package DBIx::Class::Schema::GraphQL;

use strict;
use warnings;
use version;

our $VERSION   = qv('v0.0.2');
our $AUTHORITY = 'cpan:MANWAR';

=head1 NAME

DBIx::Class::Schema::GraphQL - Auto-generate a GraphQL schema from a DBIx::Class schema

=head1 VERSION

Version v0.0.2

=cut

use MIME::Base64 qw(encode_base64 decode_base64);

use GraphQL::Schema;
use GraphQL::Type::Object;
use GraphQL::Type::InputObject;
use GraphQL::Type::List;
use GraphQL::Type::NonNull;
use GraphQL::Type::Enum;
use GraphQL::Type::Scalar qw($Int $String $Float $Boolean);

=head1 SYNOPSIS

    use DBIx::Class::Schema::GraphQL;
    use GraphQL::Execution qw(execute);

    my $db     = My::Schema->connect(...);
    my $result = DBIx::Class::Schema::GraphQL->to_graphql($db);

    # Simple plural query - always include at least one scalar field
    # alongside nodes (e.g. total) - see KNOWN BEHAVIOUR below.
    execute($result->{schema},
        '{ allBooks { total nodes { title } } }',
        undef, $result->{context});

    # Filtered + paginated + ordered
    execute($result->{schema}, '
        query {
            allBooks(
                filter:  { title_like: "%Perl%" }
                orderBy: { field: "title", direction: ASC }
                page:    { skip: 0, take: 5 }
            ) {
                total
                hasNextPage
                nodes { id title }
            }
        }', undef, $result->{context});

    # Cursor pagination
    execute($result->{schema}, '
        query($after: String) {
            allBooks(cursor: { after: $after, first: 5 }) {
                total
                nextCursor
                hasNextPage
                nodes { id title }
            }
        }', undef, $result->{context}, { after => $cursor });

    # Mutation: Full update (all non-key columns)
    execute($result->{schema},
        'mutation { createBook(title: "Dune", author_id: 4) { id title } }',
        undef, $result->{context});

    # Mutation: Sparse update (only supplied columns are changed)
    execute($result->{schema},
        'mutation { patchBook(id: 1, title: "Dune Messiah") { id title } }',
        undef, $result->{context});

=head1 DESCRIPTION

Introspects every source registered with the supplied L<DBIx::Class::Schema>
and builds a complete, executable L<GraphQL::Schema> with:

=over 4

=item * One scalar field per column, typed as C<Int>, C<Float>, C<Boolean>,
or C<String> based on the column's declared C<data_type>.

=item * One relationship field per DBIC relationship (C<has_many> resolves to
a List type; C<belongs_to> / C<might_have> resolve to a single object type).

=item * A root C<Query> type with singular lookup and plural
C<allE<lt>SourceE<gt>s> queries supporting filtering, ordering, and both
offset and cursor pagination.

=item * A root C<Mutation> type with C<createX>, C<updateX>, C<patchX>, and
C<deleteX> entry points for every source.

=back

Composite primary keys are fully supported throughout.

=head1 METHODS

=head2 to_graphql

    my $result = DBIx::Class::Schema::GraphQL->to_graphql($db);

Class method.  Accepts a connected L<DBIx::Class::Schema> instance.
Returns a hashref:

    {
        schema  => $graphql_schema,   # GraphQL::Schema, pass to execute()
        context => $db,               # the original schema, for convenience
    }

=cut

sub to_graphql {
    my ($class, $db) = @_;

    my $shared = _build_shared_types();

    # Phase 1: Shell types
    my %gql_types;
    for my $moniker ($db->sources) {
        $gql_types{$moniker} = GraphQL::Type::Object->new(
            name        => $moniker,
            description => "Auto-generated GraphQL type for DBIx::Class source '$moniker'",
            fields      => sub { {} },
        );
    }

    # Phase 2: Real fields (safe because %gql_types is fully populated)
    for my $moniker ($db->sources) {
        my $source_obj     = $db->source($moniker);
        my $this_moniker   = $moniker;
        my %types_snapshot = %gql_types;

        $gql_types{$moniker}->{fields} = sub {
            my %fields;

            for my $col ($source_obj->columns) {
                $fields{$col} = { type => _scalar_for_column($source_obj, $col) };
            }

            for my $rel ($source_obj->relationships) {
                my $rel_info       = $source_obj->relationship_info($rel);
                my $target_moniker = $rel_info->{source};
                $target_moniker    =~ s/^.*:://;

                my $target_type = $types_snapshot{$target_moniker} or next;

                my $is_plural = (
                    $rel_info->{attrs}{accessor}
                    && $rel_info->{attrs}{accessor} eq 'multi'
                ) ? 1 : 0;

                my ($captured_rel, $captured_moniker, $captured_plural)
                    = ($rel, $this_moniker, $is_plural);

                $fields{$rel} = {
                    type    => $is_plural
                                   ? GraphQL::Type::List->new(of => $target_type)
                                   : $target_type,
                    resolve => sub {
                        my ($row, $args, $ctx) = @_;
                        if (ref($row) eq 'HASH') {
                            $row = _pk_find($ctx, $captured_moniker, $row) or return;
                        }
                        if ($captured_plural) {
                            return [
                                        map { { $_->get_columns } }
                                        $row->$captured_rel->all
                                   ];
                        }
                        else {
                            my $related = $row->$captured_rel;
                            return $related ? { $related->get_columns } : undef;
                        }
                    },
                };
            }

            return \%fields;
        };
    }

    # Phase 3: Root Query + Mutation types
    my (%query_fields, %mutation_fields);

    for my $moniker ($db->sources) {
        my $graphql_type    = $gql_types{$moniker};
        my $source_obj      = $db->source($moniker);
        my $singular_args   = _build_singular_args($source_obj);
        my $filter_type     = _build_filter_type($source_obj, $moniker);
        my $connection_type = _build_connection_type($moniker, $graphql_type);

        # Singular query
        $query_fields{ lcfirst($moniker) } = {
            type    => $graphql_type,
            args    => $singular_args,
            resolve => sub {
                my ($root, $args, $ctx) = @_;
                return unless grep { defined $args->{$_} } keys %$singular_args;
                my $row = $ctx->resultset($moniker)->find($args);
                return $row ? { $row->get_columns } : undef;
            },
        };

        # Plural query with filter + pagination + ordering
        $query_fields{ 'all' . ucfirst($moniker) . 's' } = {
            type        => $connection_type,
            description => "Fetch a filtered, paginated, ordered list of $moniker rows.",
            args        => {
                filter  => { type => $filter_type,
                             description => "Column filters with exact, comparison, and logical operators." },
                page    => { type => $shared->{page_input},
                             description => "Offset pagination: skip N rows, take M rows." },
                cursor  => { type => $shared->{cursor_input},
                             description => "Cursor pagination: fetch first N rows after a cursor." },
                orderBy => { type => $shared->{order_by_input},
                             description => "Order results by a column, ASC or DESC." },
            },
            resolve => sub {
                my ($root, $args, $ctx) = @_;
                $args //= {};

                # Build the base filtered resultset
                my $rs = $ctx->resultset($moniker);
                if (my $filter = $args->{filter}) {
                    my $cond = _filter_to_dbic($filter, $ctx->source($moniker));
                    $rs = $rs->search($cond) if $cond && %$cond;
                }

                # Clone the rs for counting so pagination does not
                # affect the count query and vice-versa.
                my $count_rs = $rs->search_rs({});
                my $total    = $count_rs->count;

                my ($nodes, $next_cursor, $has_next) =
                    _apply_pagination($rs, $args, $ctx->source($moniker));

                return {
                    nodes       => $nodes,
                    total       => $total,
                    nextCursor  => $next_cursor,
                    hasNextPage => $has_next,
                };
            },
        };

        # Mutations
        %mutation_fields = (
            %mutation_fields,
            _build_mutation_fields($source_obj, $moniker, $graphql_type),
        );
    }

    my $query_type = GraphQL::Type::Object->new(
        name   => 'Query',
        fields => \%query_fields,
    );

    my $mutation_type = GraphQL::Type::Object->new(
        name        => 'Mutation',
        description => 'Auto-generated create/update/patch/delete mutations',
        fields      => \%mutation_fields,
    );

    my $schema = GraphQL::Schema->new(
        query    => $query_type,
        mutation => $mutation_type,
    );

    return {
        schema  => $schema,
        context => $db,
    };
}

#
#
# INTERNAL METHODS

# _scalar_for_column($source, $col_name)
#
# Maps a DBIC column to a GraphQL scalar. Resolution order matters:
#   1. Boolean: must come before Int because tinyint(1) is the MySQL idiom
#   2. Float  : decimal/numeric before the int catch-all
#   3. Int    : all integer family types
#   4. String : safe fallback for anything unrecognised
sub _scalar_for_column {
    my ($source, $col) = @_;
    my $info      = $source->column_info($col);
    my $data_type = $info->{data_type} // '';

    return $Boolean if $data_type =~ /(?:\b(?:bool(?:ean)?)|tinyint\(1\))(?=\s|\z)/i;
    return $Float   if $data_type =~ /\b(?:float|double(?:\s+precision)?|real|money|decimal|numeric)\b/i;
    return $Int     if $data_type =~ /\b(?:int(?:eger)?|bigint|smallint|tinyint|mediumint|serial)\b/i;
    return $String;
}

sub _col_is_required {
    my ($source, $col) = @_;
    my $info = $source->column_info($col);
    return 0 if $info->{is_auto_increment};
    return 0 if defined $info->{default_value};
    return 0 if $info->{is_nullable};
    return 1;
}

sub _pk_find {
    my ($ctx, $moniker, $row_hash) = @_;
    my $source  = $ctx->source($moniker);
    my @pk_cols = $source->primary_columns;
    my %pk_vals = map { $_ => $row_hash->{$_} } @pk_cols;
    return unless grep { defined } values %pk_vals == @pk_cols;
    return $ctx->resultset($moniker)->find(\%pk_vals);
}

sub _build_singular_args {
    my ($source) = @_;
    my %args;
    for my $pk_col ($source->primary_columns) {
        $args{$pk_col} = { type => _scalar_for_column($source, $pk_col) };
    }
    return \%args;
}

sub _build_lookup_args {
    my ($source) = @_;
    my %args;

    for my $col ($source->primary_columns) {
        $args{$col} = { type => _scalar_for_column($source, $col) };
    }

    my %unique = $source->unique_constraints;
    for my $constraint_name (keys %unique) {
        next if $constraint_name eq 'primary';
        for my $col (@{ $unique{$constraint_name} }) {
            $args{$col} //= { type => _scalar_for_column($source, $col) };
        }
    }

    return \%args;
}

sub _resolve_row {
    my ($ctx, $moniker, $args) = @_;
    my $source = $ctx->source($moniker);
    my $rs     = $ctx->resultset($moniker);

    my @pk_cols = $source->primary_columns;
    my @pk_vals = map { $args->{$_} } @pk_cols;
    unless (grep { !defined } @pk_vals) {
        my $row = $rs->find({ map { $pk_cols[$_] => $pk_vals[$_] }
                                    0 .. $#pk_cols });
        return $row if $row;
    }

    my %unique = $source->unique_constraints;
    for my $constraint_name (sort grep { $_ ne 'primary' } keys %unique) {
        my @cols = @{ $unique{$constraint_name} };
        my @vals = map { $args->{$_} } @cols;
        next if grep { !defined } @vals;
        my $row = $rs->find({ map { $cols[$_] => $vals[$_] } 0 .. $#cols });
        return $row if $row;
    }

    return undef;
}

#
# Cursors are base64(val1:val2:...), stateless, no extra dependencies.
# Colons inside values are percent-encoded so the separator is unambiguous.

sub _encode_cursor {
    my (@vals) = @_;
    my $raw = join ':', map { (my $v = $_) =~ s/%/%25/g; $v =~ s/:/%3A/g; $v } @vals;
    return encode_base64($raw, '');   # no newline
}

sub _decode_cursor {
    my ($cursor) = @_;
    my $raw  = decode_base64($cursor);
    my @vals = map { (my $v = $_) =~ s/%3A/:/gi; $v =~ s/%25/%/g; $v }
               split /:/, $raw;
    return @vals;
}

# _build_shared_types()
#
# Builds the input/enum types that are shared across all plural queries:
#
#   OrderDirection: enum  ASC | DESC
#   OrderByInput  : input { field: String!, direction: OrderDirection }
#   PageInput     : input { skip: Int, take: Int }
#   CursorInput   : input { after: String, first: Int }
#
# Returns a hashref of type objects.
sub _build_shared_types {
    my $order_direction = GraphQL::Type::Enum->new(
        name   => 'OrderDirection',
        values => {
            ASC  => { value => 'ASC'  },
            DESC => { value => 'DESC' },
        },
    );

    my $order_by_input = GraphQL::Type::InputObject->new(
        name   => 'OrderByInput',
        fields => {
            field     => { type => GraphQL::Type::NonNull->new(of => $String) },
            direction => { type => $order_direction },
        },
    );

    my $page_input = GraphQL::Type::InputObject->new(
        name   => 'PageInput',
        fields => {
            skip => { type => $Int },
            take => { type => $Int },
        },
    );

    my $cursor_input = GraphQL::Type::InputObject->new(
        name   => 'CursorInput',
        fields => {
            after => { type => $String },
            first => { type => $Int    },
        },
    );

    return {
        order_direction => $order_direction,
        order_by_input  => $order_by_input,
        page_input      => $page_input,
        cursor_input    => $cursor_input,
    };
}

# _build_filter_type($source, $moniker)
#
# Builds a per-source InputObject for filtering.  For each column we emit:
#   col     : exact match
#   col_not : inequality
#   col_like: SQL LIKE  (String columns only)
#   col_gt / col_gte / col_lt / col_lte: comparisons (Int/Float columns)
#
# Plus recursive AND / OR combinators.
sub _build_filter_type {
    my ($source, $moniker) = @_;

    # We need a forward-declaration trick for the recursive AND/OR fields.
    # Create the type object first with an empty fields sub, then fill it in.
    my $filter_type = GraphQL::Type::InputObject->new(
        name   => "${moniker}Filter",
        fields => sub { {} },    # placeholder
    );

    my %fields;

    for my $col ($source->columns) {
        my $scalar = _scalar_for_column($source, $col);
        my $name   = $scalar->name;

        # exact match
        $fields{$col} = { type => $scalar };

        # inequality
        $fields{"${col}_not"} = { type => $scalar };

        if ($name eq 'String') {
            # LIKE pattern match (String columns only)
            $fields{"${col}_like"} = { type => $String };
        }
        else {
            # Numeric / boolean comparisons
            $fields{"${col}_gt"}  = { type => $scalar };
            $fields{"${col}_gte"} = { type => $scalar };
            $fields{"${col}_lt"}  = { type => $scalar };
            $fields{"${col}_lte"} = { type => $scalar };
        }
    }

    # Recursive AND / OR — each takes a list of the same filter type
    $fields{AND} = { type => GraphQL::Type::List->new(of => $filter_type) };
    $fields{OR}  = { type => GraphQL::Type::List->new(of => $filter_type) };

    # Now replace the placeholder
    $filter_type->{fields} = sub { \%fields };

    return $filter_type;
}

# _build_connection_type($moniker, $gql_type)
#
# Builds the per-source connection wrapper returned by plural queries:
#
#   type BookConnection {
#       nodes:       [Book]
#       total:       Int
#       nextCursor:  String
#       hasNextPage: Boolean
#   }
sub _build_connection_type {
    my ($moniker, $gql_type) = @_;

    return GraphQL::Type::Object->new(
        name   => "${moniker}Connection",
        fields => {
            nodes       => { type => GraphQL::Type::List->new(of => $gql_type) },
            total       => { type => $Int     },
            nextCursor  => { type => $String  },
            hasNextPage => { type => $Boolean },
        },
    );
}

# _filter_to_dbic($filter, $source)
#
# Recursively converts a GraphQL filter hashref into a DBIC search condition.
#
#   { title_like: "%Perl%" , OR: [{ id: 1 }, { id: 2 }] }
#   => { title => { like => '%Perl%' }, -or => [ { id => 1 }, { id => 2 } ] }
sub _filter_to_dbic {
    my ($filter, $source) = @_;
    return {} unless $filter && %$filter;

    my %cond;
    my @and_parts;

    # AND / OR combinators
    if (my $and = $filter->{AND}) {
        push @and_parts, { -and => [ map { _filter_to_dbic($_, $source) } @$and ] };
    }
    if (my $or = $filter->{OR}) {
        push @and_parts, { -or  => [ map { _filter_to_dbic($_, $source) } @$or  ] };
    }

    # Column conditions
    for my $key (keys %$filter) {
        next if $key eq 'AND' || $key eq 'OR';
        next unless defined $filter->{$key};

        if ($key =~ /^(.+)_(not|like|gt|gte|lt|lte)$/) {
            my ($col, $op) = ($1, $2);
            my $dbic_op = { not => '!='   , like => 'like',
                            gt  => '>'    , gte  => '>=',
                            lt  => '<'    , lte  => '<='  }->{$op};
            push @and_parts, { $col => { $dbic_op => $filter->{$key} } };
        }
        else {
            # exact match
            push @and_parts, { $key => $filter->{$key} };
        }
    }

    return @and_parts == 1 ? $and_parts[0]
         : @and_parts >  1 ? { -and => \@and_parts }
         :                   {};
}

# _apply_pagination($rs, $args, $source)
#
# Applies ordering, then either offset (page) or cursor (cursor) pagination.
# Returns ($paged_rs, $next_cursor, $has_next_page).
#
# Precedence: cursor pagination wins if both are supplied.
sub _apply_pagination {
    my ($rs, $args, $source) = @_;

    my @pk_cols = $source->primary_columns;

    # Ordering
    my $order_by = $args->{orderBy};
    if ($order_by && $order_by->{field}) {
        my $dir = lc($order_by->{direction} // 'ASC');
        $rs = $rs->search(undef, {
            order_by => { "-$dir" => $order_by->{field} }
        });
    }
    else {
        # Default: stable order by PK
        $rs = $rs->search(undef, { order_by => [ map { { -asc => $_ } } @pk_cols ] });
    }

    # Cursor pagination
    if (my $cursor_args = $args->{cursor}) {
        my $first = $cursor_args->{first} // 10;
        my $after = $cursor_args->{after};

        if ($after) {
            my @decoded = _decode_cursor($after);
            if (@pk_cols == 1) {
                # Simple: WHERE pk > cursor_val (works for ordered-by-PK default)
                $rs = $rs->search({ $pk_cols[0] => { '>' => $decoded[0] } });
            }
            else {
                # Composite PK: fetch everything after decoded position
                # by re-applying a compound condition
                my %after_cond = map { $pk_cols[$_] => { '>' => $decoded[$_] } }
                                     0 .. $#pk_cols;
                $rs = $rs->search(\%after_cond);
            }
        }

        # Fetch one extra to detect hasNextPage
        my @rows    = $rs->search(undef, { rows => $first + 1 })->all;
        my $has_next = @rows > $first;
        @rows = @rows[0 .. $first - 1] if $has_next;

        my $next_cursor;
        if ($has_next && @rows) {
            my $last_row = $rows[-1];
            $next_cursor = _encode_cursor(map { $last_row->get_column($_) } @pk_cols);
        }

        return (
            [ map { { $_->get_columns } } @rows ],
            $next_cursor,
            $has_next ? 1 : 0,
        );
    }

    # Offset pagination
    if (my $page_args = $args->{page}) {
        my $skip = $page_args->{skip} // 0;
        my $take = $page_args->{take} // 10;
        my @rows = $rs->search(undef, { rows => $take, offset => $skip })->all;
        return (
            [ map { { $_->get_columns } } @rows ],
            undef,   # no cursor for offset pagination
            0,
        );
    }

    # No pagination: return everything
    my @rows = $rs->all;
    return (
        [ map { { $_->get_columns } } @rows ],
        undef,
        0,
    );
}

sub _build_mutation_fields {
    my ($source, $moniker, $gql_type) = @_;
    my %fields;

    my @pk_cols   = $source->primary_columns;
    my %is_pk     = map { $_ => 1 } @pk_cols;
    my @all_cols  = $source->columns;
    my @data_cols = grep { !$is_pk{$_} } @all_cols;

    # createX
    my %create_args;
    for my $col (@all_cols) {
        my $scalar = _scalar_for_column($source, $col);
        $create_args{$col} = {
            type => _col_is_required($source, $col)
                        ? GraphQL::Type::NonNull->new(of => $scalar)
                        : $scalar,
        };
    }

    $fields{ 'create' . ucfirst($moniker) } = {
        type        => $gql_type,
        args        => \%create_args,
        description => "Insert a new $moniker row.  Required columns are marked non-null.",
        resolve     => sub {
            my ($root, $args, $ctx) = @_;
            my %data = map  { $_ => $args->{$_} }
                       grep { defined $args->{$_} } keys %$args;
            my $row  = eval { $ctx->resultset($moniker)->create(\%data) };
            die $@ if $@;
            return { $row->get_columns };
        },
    };

    # updateX — full replacement; all non-key columns should be supplied.
    my %update_lookup_args = %{ _build_lookup_args($source) };
    my %update_data_args   = map {
        $_ => { type => _scalar_for_column($source, $_) }
    } @data_cols;

    $fields{ 'update' . ucfirst($moniker) } = {
        type        => $gql_type,
        args        => { %update_lookup_args, %update_data_args },
        description => "Full update of a $moniker row identified by its primary key "
                     . "or any unique constraint.  All non-key columns should be "
                     . "supplied; omitted columns are left unchanged in the database "
                     . "but that is incidental — use patchX for intentional sparse updates.",
        resolve     => sub {
            my ($root, $args, $ctx) = @_;
            my $row = _resolve_row($ctx, $moniker, $args);
            die "No $moniker row found for the supplied key(s)\n" unless $row;
            my %data = map  { $_ => $args->{$_} }
                       grep { !$is_pk{$_} && defined $args->{$_} } keys %$args;
            $row = eval { $row->update(\%data); $row->discard_changes; $row };
            die $@ if $@;
            return { $row->get_columns };
        },
    };

    # patchX — sparse update; only columns explicitly provided are changed.
    # Identified by primary key or any unique constraint, same as updateX.
    # Every non-key column is optional (nullable).  Only defined arguments
    # are sent to ->update(), so the caller can safely omit any column they
    # do not wish to change.
    $fields{ 'patch' . ucfirst($moniker) } = {
        type        => $gql_type,
        args        => { %update_lookup_args, %update_data_args },
        description => "Sparse update of a $moniker row identified by its primary key "
                     . "or any unique constraint.  Supply only the columns you want "
                     . "to change; all other columns are left untouched.",
        resolve     => sub {
            my ($root, $args, $ctx) = @_;
            my $row = _resolve_row($ctx, $moniker, $args);
            die "No $moniker row found for the supplied key(s)\n" unless $row;
            # Only send columns the client explicitly provided.
            # GraphQL omits absent args from the hash entirely, so a
            # defined-check is sufficient to distinguish "not sent" from null.
            my %data = map  { $_ => $args->{$_} }
                       grep { !$is_pk{$_} && defined $args->{$_} } keys %$args;
            die "patchX: no non-key columns supplied — nothing to update\n"
                unless %data;
            $row = eval { $row->update(\%data); $row->discard_changes; $row };
            die $@ if $@;
            return { $row->get_columns };
        },
    };

    # deleteX
    $fields{ 'delete' . ucfirst($moniker) } = {
        type        => $Boolean,
        args        => _build_lookup_args($source),
        description => "Delete a $moniker row identified by its primary key "
                     . "or any unique constraint.  Returns true on success.",
        resolve     => sub {
            my ($root, $args, $ctx) = @_;
            my $row = _resolve_row($ctx, $moniker, $args);
            return 0 unless $row;
            eval { $row->delete };
            return $@ ? 0 : 1;
        },
    };

    return %fields;
}

=head1 SCALAR TYPE MAPPING

SQL column types are mapped to GraphQL scalars in the following priority order:

    Boolean: bool, boolean, tinyint(1)
    Float  : float, double, double precision, real, money, decimal, numeric
    Int    : int, integer, bigint, smallint, tinyint, mediumint, serial
    String : everything else (safe fallback)

=head1 PLURAL QUERIES

Every source C<X> gets an C<allXs> query returning an C<XConnection>:

    type XConnection {
        nodes:       [X]
        total:       Int        # total rows matching filter, before pagination
        nextCursor:  String     # opaque cursor; set only during cursor pagination
        hasNextPage: Boolean    # true when more pages follow
    }

Always request C<total> or another scalar field alongside C<nodes> in your
selection set - see L</KNOWN BEHAVIOUR>.

=head2 Filtering

    allBooks(filter: { title_like: "%Perl%", author_id: 3 }) {
        total nodes { title }
    }

Per-column operators:

    col           exact match
    col_not       inequality  (!=)
    col_like      LIKE pattern  (String columns only)
    col_gt        greater than
    col_gte       greater than or equal
    col_lt        less than
    col_lte       less than or equal

Logical combinators (nest recursively and combine freely):

    allBooks(filter: {
        AND: [
            { author_id: 1 }
            { OR: [{ title_like: "%Hobbit%" }, { title_like: "%Ring%" }] }
        ]
    }) { total nodes { title } }

=head2 Ordering

    allBooks(orderBy: { field: "title", direction: ASC }) {
        total nodes { title }
    }

C<direction> is the C<OrderDirection> enum: C<ASC> or C<DESC>.  When omitted,
results are ordered by primary key ascending.

=head2 Offset pagination

    allBooks(page: { skip: 10, take: 5 }) { total nodes { title } }

C<skip> defaults to 0, C<take> defaults to 10.

=head2 Cursor pagination

    # First page
    allBooks(cursor: { first: 5 }) {
        total nextCursor hasNextPage nodes { title }
    }

    # Subsequent pages - pass nextCursor from the previous response
    allBooks(cursor: { after: "...", first: 5 }) {
        total nextCursor hasNextPage nodes { title }
    }

C<first> defaults to 10.  Cursor pagination takes precedence over offset
pagination if both are supplied in the same query.  Cursors are opaque
base64-encoded strings derived from the row's primary key and should be
treated as implementation details subject to change.

=head1 MUTATIONS

For every source C<X>, four mutations are generated:

=head2 createX

    mutation { createBook(title: "Dune", author_id: 4) { id title } }

Accepts all column values as arguments.  Columns that are non-nullable,
have no declared default, and are not auto-increment are wrapped in
C<NonNull> and must be supplied.  On failure, C<die>s - the error appears
in the top-level C<errors> array of the response.

=head2 updateX

    mutation { updateBook(id: 1, title: "Dune Messiah", author_id: 4) { id title } }

Full update. Identifies the target row by its primary key B<or> by a
complete set of columns from any unique constraint declared on the source.
All non-key columns should be supplied.  C<die>s if the row cannot be found
or the update fails.

Use C<patchX> when you only want to change a subset of columns.

=head2 patchX

    mutation { patchBook(id: 1, title: "Dune Messiah") { id title } }

Sparse (partial) update.  Identifies the target row the same way as
C<updateX> (primary key or unique constraint), but only the non-key columns
you explicitly supply are written to the database.  Any column you omit is
left exactly as it is.

    # Change only the title - author_id is untouched
    mutation { patchBook(id: 1, title: "Dune Messiah") { id title author { name } } }

    # Change only the foreign key - title is untouched
    mutation { patchBook(id: 1, author_id: 2) { id title author { name } } }

C<die>s if the row cannot be found, the update fails, or no non-key
columns are supplied at all.

=head2 deleteX

    mutation { deleteBook(id: 1) }

Identifies the target row by primary key or unique constraint.  Returns
C<true> (C<Boolean>) on success, C<false> if the row is not found.

=head1 ERROR HANDLING

C<createX> and C<updateX> resolver failures C<die>.  GraphQL catches the
exception and surfaces it in the top-level C<errors> array; the C<data>
field for the failed mutation will be C<null>.  C<deleteX> returns C<false>
rather than dying when a row is not found.

=head1 LIMITATIONS

=over 4

=item * B<Relationship fields are unfiltered.>  Relationship fields within a
query (e.g. C<author { books { title } }>) return all related rows.  They do
not accept C<filter>, C<orderBy>, or pagination arguments.

=item * B<No nested input for mutations.>  C<createX> and C<updateX> accept
only scalar column values.  Related rows must be created or linked separately
using their own mutations and raw foreign-key values.

=item * B<updateX is a full update.>  All non-primary-key columns should be
supplied; use C<patchX> for intentional sparse / partial updates.

=item * B<Cursor pagination assumes primary-key order.>  The C<after> cursor
encodes the primary key of the last returned row and applies a
C<pk E<gt> value> condition.  If you supply a custom C<orderBy> using a
non-primary-key column, the cursor will not advance correctly.  Use offset
pagination (C<page>) when ordering by non-PK columns.

=item * B<No custom scalars.>  Column types such as C<date>, C<datetime>,
C<json>, and C<uuid> all map to C<String>.  Custom GraphQL scalars are not
generated.

=item * B<No subscriptions.>  Only C<Query> and C<Mutation> operation types
are generated.

=item * B<C<col_like> case sensitivity is database-dependent.>  SQLite
C<LIKE> is case-insensitive for ASCII characters but case-sensitive for
Unicode.  PostgreSQL C<LIKE> is always case-sensitive.  Use C<col_like>
accordingly.

=back

=head1 KNOWN BEHAVIOUR

When querying a plural C<allXs> field, always include at least one scalar
field (C<total>, C<hasNextPage>, or C<nextCursor>) alongside C<nodes> in
your selection set:

    # Correct
    { allBooks { total nodes { title } } }

    # May silently return empty nodes in some GraphQL executor versions
    { allBooks { nodes { title } } }

This is a quirk of how C<GraphQL::Execution> resolves connection object
types when the selection set contains only a list field.

=head1 DEPENDENCIES

L<DBIx::Class>, L<GraphQL::Schema>, L<GraphQL::Type::Object>,
L<GraphQL::Type::InputObject>, L<GraphQL::Type::List>,
L<GraphQL::Type::NonNull>, L<GraphQL::Type::Enum>,
L<GraphQL::Type::Scalar>, L<MIME::Base64> (core).

=head1 SEE ALSO

L<GraphQL::Plugin::Convert::DBIC>, L<DBIx::Class::Schema>, L<GraphQL::Schema>

=head1 AUTHOR

Mohammad Sajid Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/manwar/DBIx-Class-Schema-GraphQL>

=head1 BUGS

Please report any bugs or feature requests through the web interface at L<https://github.com/manwar/DBIx-Class-Schema-GraphQL/issues>.
I will  be notified and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc DBix::Class::Schema::GraphQL

You can also look for information at:

=over 4

=item * BUG Report

L<https://github.com/manwar/DBIx-Class-Schema-GraphQL/issues>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/DBIx-Class-Schema-GraphQL>

=item * Search MetaCPAN

L<https://metacpan.org/dist/DBIx-Class-Schema-GraphQL>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Mohammad Sajid Anwar.

This program  is  free software; you can redistribute it and / or modify it under
the  terms  of the the Artistic License (2.0). You may obtain a  copy of the full
license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any  use,  modification, and distribution of the Standard or Modified Versions is
governed by this Artistic License.By using, modifying or distributing the Package,
you accept this license. Do not use, modify, or distribute the Package, if you do
not accept this license.

If your Modified Version has been derived from a Modified Version made by someone
other than you,you are nevertheless required to ensure that your Modified Version
 complies with the requirements of this license.

This  license  does  not grant you the right to use any trademark,  service mark,
tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge patent license
to make,  have made, use,  offer to sell, sell, import and otherwise transfer the
Package with respect to any patent claims licensable by the Copyright Holder that
are  necessarily  infringed  by  the  Package. If you institute patent litigation
(including  a  cross-claim  or  counterclaim) against any party alleging that the
Package constitutes direct or contributory patent infringement,then this Artistic
License to you shall terminate on the date that such litigation is filed.

Disclaimer  of  Warranty:  THE  PACKAGE  IS  PROVIDED BY THE COPYRIGHT HOLDER AND
CONTRIBUTORS  "AS IS'  AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES. THE IMPLIED
WARRANTIES    OF   MERCHANTABILITY,   FITNESS   FOR   A   PARTICULAR  PURPOSE, OR
NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY YOUR LOCAL LAW. UNLESS
REQUIRED BY LAW, NO COPYRIGHT HOLDER OR CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL,  OR CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE
OF THE PACKAGE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

1; # End of DBIx::Class::Schema::GraphQL
