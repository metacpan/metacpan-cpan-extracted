package DBIO::GraphQL;
# ABSTRACT: Auto-generate a GraphQL schema from a DBIO schema
our $VERSION = '0.900000';
use strict;
use warnings;

use MIME::Base64 qw(encode_base64 decode_base64);

use GraphQL::Schema;
use GraphQL::Type::Object;
use GraphQL::Type::List;
use GraphQL::Type::Enum;
use GraphQL::Type::Scalar qw($Int $String $Boolean);

use DBIO::GraphQL::ScalarMap;
use DBIO::GraphQL::Filter::Search;
use DBIO::GraphQL::Relationship;
use DBIO::GraphQL::Mutation;


sub to_graphql {
  my ($class, $db) = @_;

  my $filter       = DBIO::GraphQL::Filter::Search->new(schema => $db);
  my $relationship = DBIO::GraphQL::Relationship->new(schema => $db);
  my $mutation     = DBIO::GraphQL::Mutation->new(schema => $db);

  my $shared = _build_shared_types();

  # Phase 1: shell types (one per source). Empty fields sub; filled
  # in Phase 2 once every source has a shell.
  my %gql_types;
  for my $moniker ($db->sources) {
    $gql_types{$moniker} = GraphQL::Type::Object->new(
      name        => $moniker,
      description => "Auto-generated GraphQL type for DBIO source '$moniker'",
      fields      => sub { {} },
    );
  }

  # Phase 2: real fields. Snapshot of %gql_types at the top so that
  # a relationship's target type lookup never accidentally sees a
  # half-built object in this same loop iteration.
  for my $moniker ($db->sources) {
    my $source_obj     = $db->source($moniker);
    my %types_snapshot = %gql_types;

    $gql_types{$moniker}->{fields} = sub {
      my %fields;

      for my $col ($source_obj->columns) {
        $fields{$col} = {
          type => DBIO::GraphQL::ScalarMap::for_column($source_obj, $col),
        };
      }

      for my $rel ($source_obj->relationships) {
        my $field = $relationship->build_field(
          $source_obj, $rel, \%types_snapshot
        );
        $fields{$rel} = $field if $field;
      }

      return \%fields;
    };
  }

  # Phase 3: root Query + Mutation types
  my (%query_fields, %mutation_fields);

  for my $moniker ($db->sources) {
    my $graphql_type    = $gql_types{$moniker};
    my $source_obj      = $db->source($moniker);
    my $singular_args   = _build_singular_args($source_obj);
    my $filter_type     = $filter->type_for($moniker);
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
                     description => "Per-column nested filters (eq/not/gt/gte/lt/lte/in/like/contains/startsWith/endsWith/isNull) plus AND/OR combinators." },
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

        my $rs = $ctx->resultset($moniker);
        if (my $cond = $filter->to_search($args->{filter}, $moniker)) {
          $rs = $rs->search($cond);
        }

        # Count uses a clone so pagination does not affect the
        # count query and vice-versa.
        my $count_rs = $rs->search_rs({});
        my $total    = $count_rs->count;

        my ($nodes, $next_cursor, $has_next) =
          _apply_pagination($rs, $args, $source_obj);

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
      %{ $mutation->fields_for($source_obj, $moniker, $graphql_type) },
    );
  }

  my $query_type = GraphQL::Type::Object->new(
    name   => 'Query',
    fields => \%query_fields,
  );

  my $mutation_type = GraphQL::Type::Object->new(
    name        => 'Mutation',
    description => 'Auto-generated create/update/delete mutations',
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
# INTERNAL HELPERS
#

sub _build_singular_args {
  my ($source) = @_;
  my %args;
  for my $col ($source->primary_columns) {
    $args{$col} = { type => DBIO::GraphQL::ScalarMap::for_column($source, $col) };
  }
  return \%args;
}

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
      skip => { type => $Int    },
      take => { type => $Int    },
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

# _build_connection_type($moniker, $gql_type)
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

# _encode_cursor / _decode_cursor
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

# _apply_pagination($rs, $args, $source)
#
# Applies ordering, then either offset (page) or cursor (cursor) pagination.
# Returns ($nodes, $next_cursor, $has_next).
#
# Precedence: cursor pagination wins if both are supplied.
sub _apply_pagination {
  my ($rs, $args, $source) = @_;

  my @pk_cols = $source->primary_columns;

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

  if (my $cursor_args = $args->{cursor}) {
    my $first = $cursor_args->{first} // 10;
    my $after = $cursor_args->{after};

    if ($after) {
      my @decoded = _decode_cursor($after);
      if (@pk_cols == 1) {
        $rs = $rs->search({ $pk_cols[0] => { '>' => $decoded[0] } });
      }
      else {
        my %after_cond = map { $pk_cols[$_] => { '>' => $decoded[$_] } }
                             0 .. $#pk_cols;
        $rs = $rs->search(\%after_cond);
      }
    }

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

  if (my $page_args = $args->{page}) {
    my $skip = $page_args->{skip} // 0;
    my $take = $page_args->{take} // 10;
    my @rows = $rs->search(undef, { rows => $take, offset => $skip })->all;
    return (
      [ map { { $_->get_columns } } @rows ],
      undef,
      0,
    );
  }

  my @rows = $rs->all;
  return (
    [ map { { $_->get_columns } } @rows ],
    undef,
    0,
  );
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::GraphQL - Auto-generate a GraphQL schema from a DBIO schema

=head1 VERSION

version 0.900000

=head1 SYNOPSIS

  use DBIO::GraphQL;
  use GraphQL::Execution qw(execute);

  my $db     = My::Schema->connect(...);
  my $result = DBIO::GraphQL->to_graphql($db);

  # Simple plural query - always include at least one scalar field
  # alongside nodes (e.g. total) - see KNOWN BEHAVIOUR below.
  execute($result->{schema},
    '{ allBooks { total nodes { title } } }',
    undef, $result->{context});

  # Filtered + paginated + ordered (nested-DBIO-style filter)
  execute($result->{schema}, '
    query {
      allBooks(
        filter:  { title: { like: "%Perl%" } }
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

  # Mutation
  execute($result->{schema},
    'mutation { createBook(title: "Dune", author_id: 4) { id title } }',
    undef, $result->{context});

=head1 DESCRIPTION

Introspects every source registered with the supplied L<DBIO::Schema>
and builds a complete, executable L<GraphQL::Schema> with:

=over 4

=item * One scalar field per column, typed as C<Int>, C<Float>,
C<Boolean>, or C<String> based on the column's declared C<data_type>.

=item * One relationship field per DBIO relationship (C<has_many>
resolves to a List type; C<belongs_to> / C<might_have> resolve to a
single object type). Build-time errors are emitted when the DBIO
relationship contract is incomplete (see L<DBIO::GraphQL::Relationship>).

=item * A root C<Query> type with singular lookup and plural
C<allE<lt>SourceE<gt>s> queries supporting filtering, ordering, and both
offset and cursor pagination. Filter arguments use a nested per-column
shape that mirrors the DBIO search-condition format (see
L<DBIO::GraphQL::Filter>).

=item * A root C<Mutation> type with C<createX>, C<updateX>, and
C<deleteX> entry points for every source (see L<DBIO::GraphQL::Mutation>).

=back

Composite primary keys are fully supported throughout.

=head1 METHODS

=head2 to_graphql

  my $result = DBIO::GraphQL->to_graphql($db);

Class method. Accepts a connected L<DBIO::Schema> instance. Returns a
hashref:

  {
    schema  => $graphql_schema,   # GraphQL::Schema, pass to execute()
    context => $db,               # the original schema, for convenience
  }

=head1 SCALAR TYPE MAPPING

SQL column types are mapped to GraphQL scalars in the following priority order:

  Boolean: bool, boolean, tinyint(1)
  Float  : float, double, double precision, real, money, decimal, numeric
  Int    : int, integer, bigint, smallint, tinyint, mediumint, serial
  String : everything else (safe fallback)

The mapping is centralised in L<DBIO::GraphQL::ScalarMap> and reused by
the filter, mutation, and relationship modules.

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

Filter arguments use a nested per-column shape that mirrors the DBIO
search-condition format. Each column accepts a typed C<*Filter> input
with operators that depend on the column's scalar type
(C<IntFilter>, C<FloatFilter>, C<StringFilter>, C<BoolFilter>).

  allBooks(filter: {
    title:     { like:    "%Perl%" }
    author_id: { gt:      3 }
    active:    { eq:      true }
    AND: [
      { title: { contains: "Hobbit" } }
      { OR:    [ { title: { contains: "Ring" } }, { author_id: { gt: 5 } } ] }
    ]
  }) { total nodes { title } }

Per-scalar operators:

  IntFilter / FloatFilter
    eq, not, gt, gte, lt, lte, in, isNull

  StringFilter
    eq, not, like, contains, startsWith, endsWith, in, isNull

  BoolFilter
    eq, not, isNull

Logical combinators (available on every per-source filter):

  AND: [ Filter, Filter, ... ]
  OR:  [ Filter, Filter, ... ]

=head2 Ordering

  allBooks(orderBy: { field: "title", direction: ASC }) {
    total nodes { title }
  }

C<direction> is the C<OrderDirection> enum: C<ASC> or C<DESC>. When
omitted, results are ordered by primary key ascending.

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

C<first> defaults to 10. Cursor pagination takes precedence over
offset pagination if both are supplied in the same query. Cursors are
opaque base64-encoded strings derived from the row's primary key and
should be treated as implementation details subject to change.

=head1 MUTATIONS

For every source C<X>, three mutations are generated by
L<DBIO::GraphQL::Mutation>:

=head2 createX

  mutation { createBook(title: "Dune", author_id: 4) { id title } }

Accepts all column values as arguments. Columns that are non-nullable,
have no declared default, and are not auto-increment are wrapped in
C<NonNull> and must be supplied. On failure, C<die>s - the error
appears in the top-level C<errors> array of the response.

=head2 updateX

  mutation { updateBook(id: 1, title: "Dune Messiah") { id title } }

Identifies the target row by its primary key B<or> by a complete set
of columns from any unique constraint declared on the source. All
non-key columns must be supplied (full update). C<die>s if the row
cannot be found or the update fails.

=head2 deleteX

  mutation { deleteBook(id: 1) }

Identifies the target row by primary key or unique constraint.
Returns C<true> (C<Boolean>) on success, C<false> if the row is not
found.

=head1 ERROR HANDLING

=over 4

=item *

C<createX> and C<updateX> resolver failures C<die>. GraphQL catches
the exception and surfaces it in the top-level C<errors> array; the
C<data> field for the failed mutation will be C<null>.

=item *

C<deleteX> returns C<false> rather than dying when a row is not found.

=item *

Relationship resolution C<die>s at build time when the DBIO
relationship contract is incomplete (see
L<DBIO::GraphQL::Relationship>). Set C<< on_error => 'warn' >> on
the resolver to downgrade to a warning + silent skip.

=back

=head1 LIMITATIONS

=over 4

=item * B<Relationship fields are unfiltered.> Relationship fields
within a query (e.g. C<author { books { title } }>) return all
related rows. They do not accept C<filter>, C<orderBy>, or pagination
arguments.

=item * B<No nested input for mutations.> C<createX> and C<updateX>
accept only scalar column values. Related rows must be created or
linked separately using their own mutations and raw foreign-key
values.

=item * B<updateX is a full update.> All non-primary-key columns
must be supplied; partial (sparse) updates are not supported.

=item * B<Cursor pagination assumes primary-key order.> The
C<after> cursor encodes the primary key of the last returned row
and applies a C<pk E<gt> value> condition. If you supply a custom
C<orderBy> using a non-primary-key column, the cursor will not
advance correctly. Use offset pagination (C<page>) when ordering by
non-PK columns.

=item * B<No custom scalars.> Column types such as C<date>,
C<datetime>, C<json>, and C<uuid> all map to C<String>. Custom
GraphQL scalars are not generated.

=item * B<No subscriptions.> Only C<Query> and C<Mutation> operation
types are generated.

=item * B<col_like case sensitivity is database-dependent.> SQLite
C<LIKE> is case-insensitive for ASCII characters but case-sensitive
for Unicode. PostgreSQL C<LIKE> is always case-sensitive.

=back

=head1 KNOWN BEHAVIOUR

When querying a plural C<allXs> field, always include at least one
scalar field (C<total>, C<hasNextPage>, or C<nextCursor>) alongside
C<nodes> in your selection set:

  # Correct
  { allBooks { total nodes { title } } }

  # May silently return empty nodes in some GraphQL executor versions
  { allBooks { nodes { title } } }

This is a quirk of how C<GraphQL::Execution> resolves connection
object types when the selection set contains only a list field.

=head1 ARCHITECTURE

L<DBIO::GraphQL> is a thin orchestrator over four focused modules:

=over 4

=item * L<DBIO::GraphQL::ScalarMap> - column data_type → GraphQL scalar

=item * L<DBIO::GraphQL::Filter> (and L<DBIO::GraphQL::Filter::Search>,
L<DBIO::GraphQL::Filter::Null>) - per-source GraphQL InputObject
translating nested filter args into DBIO search conditions

=item * L<DBIO::GraphQL::Relationship> - relationship field
resolution with strict contract validation (closes KARR #1)

=item * L<DBIO::GraphQL::Mutation> - createX / updateX / deleteX
per source

=back

=head1 ACKNOWLEDGEMENTS

DBIO port of
L<DBIx::Class::Schema::GraphQL|https://metacpan.org/pod/DBIx::Class::Schema::GraphQL>
by Mohammad Sajid Anwar (MANWAR). The original C<DBIx::Class>
implementation, design, and documentation are his work; this
distribution adapts them to the L<DBIO> schema introspection API
and re-architects the filter surface into a nested per-column shape
that mirrors DBIO's native search-condition format.

=head1 SEE ALSO

L<DBIx::Class::Schema::GraphQL>, L<GraphQL::Plugin::Convert::DBIC>,
L<DBIO::Schema>, L<GraphQL::Schema>

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
