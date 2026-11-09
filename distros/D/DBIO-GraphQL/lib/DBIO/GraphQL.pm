package DBIO::GraphQL;
# ABSTRACT: Auto-generate a GraphQL schema from a DBIO schema
our $VERSION = '0.900004';
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
use DBIO::GraphQL::Policy;

use GraphQL::Language::Parser ();
use GraphQL::Execution ();
use DBIO::GraphQL::Limits;
use DBIO::GraphQL::Error qw(client_error);


my %OPTIONS = map { $_ => 1 } qw(
  sources except hide readonly mutations authorize on_error introspection
  default_rows max_rows max_in max_depth max_cost
);

sub to_graphql {
  my ($class, $db, %opts) = @_;

  for my $opt (sort keys %opts) {
    die "DBIO::GraphQL: unknown to_graphql option '$opt'\n"
      unless $OPTIONS{$opt};
  }
  my $policy = DBIO::GraphQL::Policy->new(schema => $db, %opts);
  my @monikers = $policy->monikers;

  my $filter       = DBIO::GraphQL::Filter::Search->new(schema => $db, policy => $policy);
  my $relationship = DBIO::GraphQL::Relationship->new(schema => $db, policy => $policy);
  my $mutation     = DBIO::GraphQL::Mutation->new(schema => $db, policy => $policy);

  my $shared = _build_shared_types();

  # The error envelope around every resolver: client errors pass, a database
  # refusal is classified, anything else is "internal error" (DBIO::GraphQL::Error).
  my $guard = sub {
    my ($field) = @_;
    $field->{resolve} = DBIO::GraphQL::Error->guard($field->{resolve}, $policy->on_error)
      if $field->{resolve};
    return $field;
  };

  # Phase 1: shell types (one per source). Empty fields sub; filled
  # in Phase 2 once every source has a shell.
  my %gql_types;
  for my $moniker (@monikers) {
    $gql_types{$moniker} = GraphQL::Type::Object->new(
      name        => $moniker,
      description => "Auto-generated GraphQL type for DBIO source '$moniker'",
      fields      => sub { {} },
    );
  }

  # Phase 2: real fields. Snapshot of %gql_types at the top so that
  # a relationship's target type lookup never accidentally sees a
  # half-built object in this same loop iteration.
  for my $moniker (@monikers) {
    my $source_obj     = $db->source($moniker);
    my %types_snapshot = %gql_types;
    my @visible        = $policy->visible_columns($moniker);
    die "DBIO::GraphQL: source '$moniker' has no visible column\n" unless @visible;

    $gql_types{$moniker}->{fields} = sub {
      my %fields;

      for my $col (@visible) {
        $fields{$col} = {
          type => DBIO::GraphQL::ScalarMap::for_column($source_obj, $col),
        };
      }

      for my $rel ($source_obj->relationships) {
        my $field = $relationship->build_field(
          $source_obj, $rel, \%types_snapshot
        );
        $fields{$rel} = $guard->($field) if $field;
      }

      return \%fields;
    };
  }

  # Phase 3: root Query + Mutation types
  my (%query_fields, %mutation_fields);

  for my $moniker (@monikers) {
    my $graphql_type    = $gql_types{$moniker};
    my $source_obj      = $db->source($moniker);
    my $singular_args   = _build_singular_args($source_obj);
    my $filter_type     = $filter->type_for($moniker);
    my $connection_type = _build_connection_type($moniker, $graphql_type);

    # Singular query - only for sources with a primary key, it is the
    # lookup by that key.
    if (%$singular_args) {
      $query_fields{ lcfirst($moniker) } = {
        type    => $graphql_type,
        args    => $singular_args,
        resolve => sub {
          my ($root, $args, $ctx) = @_;
          my $restriction = $policy->authorize('get', $moniker, $args, $ctx);
          my @missing = grep { !defined $args->{$_} } sort keys %$singular_args;
          die client_error "DBIO::GraphQL: query '" . lcfirst($moniker)
            . "' needs every primary key argument, missing: "
            . join(', ', @missing) . "\n" if @missing;
          my $rs = $ctx->resultset($moniker);
          $rs = $rs->search($restriction) if $restriction;
          my $row = $rs->find($args);
          return $row ? { $row->get_columns } : undef;
        },
      };
    }

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
        my ($root, $args, $ctx, $info) = @_;
        $args //= {};

        my $restriction = $policy->authorize('list', $moniker, $args, $ctx);
        _check_max_rows($policy, $args);
        my $rs = $ctx->resultset($moniker);
        $rs = $rs->search($restriction) if $restriction;
        if (my $cond = $filter->to_search($args->{filter}, $moniker)) {
          $rs = $rs->search($cond);
        }

        # The count runs only when total is selected, on a clone so
        # pagination does not affect it and vice-versa.
        my $total;
        if (_selects_field($info, 'total')) {
          $total = $rs->search_rs({})->count;
        }

        my ($nodes, $next_cursor, $has_next) =
          _apply_pagination($rs, $args, $source_obj, $policy);

        return {
          nodes       => $nodes,
          total       => $total,
          nextCursor  => $next_cursor,
          hasNextPage => $has_next,
        };
      },
    };

    # Mutations, only for the sources that opted in
    if ($policy->has_mutations($moniker)) {
      %mutation_fields = (
        %mutation_fields,
        %{ $mutation->fields_for($source_obj, $moniker, $graphql_type) },
      );
    }
  }

  $guard->($_) for values %query_fields, values %mutation_fields;

  my $query_type = GraphQL::Type::Object->new(
    name   => 'Query',
    fields => \%query_fields,
  );

  my $mutation_type = %mutation_fields
    ? GraphQL::Type::Object->new(
        name        => 'Mutation',
        description => 'Auto-generated create/update/delete mutations',
        fields      => \%mutation_fields,
      )
    : undef;

  my $schema = GraphQL::Schema->new(
    query => $query_type,
    ($mutation_type ? (mutation => $mutation_type) : ()),
  );

  my $result = {
    schema        => $schema,
    context       => $db,
    introspection => $policy->introspection,
  };

  # The entry point: parse once, check the document, then run the engine.
  # A check that fails answers with an errors list, before any SQL.
  $result->{execute} = sub {
    my ($query, $root, $context, $variables, $operation) = @_;
    my $ast = ref $query ? $query : eval { GraphQL::Language::Parser::parse($query) };
    if ($ast) {
      my $ok = eval {
        $class->_check_ast({ introspection => $policy->introspection }, $ast);
        DBIO::GraphQL::Limits->check(
          ast       => $ast,
          schema    => $schema,
          policy    => $policy,
          variables => $variables,
          operation => $operation,
        );
        1;
      };
      unless ($ok) {
        (my $message = $@) =~ s/\s+\z//;
        return { errors => [ { message => $message } ] };
      }
    }
    return GraphQL::Execution::execute(
      $schema, $ast // $query, $root, $context, $variables, $operation);
  };

  return $result;
}


sub check_document {
  my ($class, $result, $query) = @_;
  return if $result->{introspection};
  my $ast = eval { GraphQL::Language::Parser::parse($query) } or return;
  $class->_check_ast($result, $ast);
  return;
}

sub _check_ast {
  my ($class, $result, $ast) = @_;
  return if $result->{introspection};
  die "DBIO::GraphQL: introspection is disabled\n"
    if _selects_introspection($ast);
  return;
}

# _selects_field($info, $name)
#
# True when the selection set of the field being resolved names $name,
# directly, under an alias, or through a fragment or inline fragment.
# Without resolve info (nothing known) the answer is true.
sub _selects_field {
  my ($info, $name) = @_;
  return 1 unless $info && $info->{field_nodes};
  my %seen;
  my $walk; $walk = sub {
    for my $node (@{ $_[0] }) {
      my $kind = $node->{kind} // '';
      if ($kind eq 'field') {
        return 1 if ($node->{name} // '') eq $name;
      }
      elsif ($kind eq 'fragment_spread') {
        my $frag = $info->{fragments} && $info->{fragments}{ $node->{name} };
        next if !$frag || $seen{ $node->{name} }++;
        return 1 if $walk->($frag->{selections} || []);
      }
      elsif ($kind eq 'inline_fragment') {
        return 1 if $walk->($node->{selections} || []);
      }
    }
    return 0;
  };
  my $found = 0;
  for my $field (@{ $info->{field_nodes} }) {
    $found = $walk->($field->{selections} || []) and last;
  }
  undef $walk;
  return $found;
}

sub _selects_introspection {
  my ($nodes) = @_;
  for my $node (@$nodes) {
    return 1 if ($node->{kind} // '') eq 'field'
             && ($node->{name} // '') =~ /\A__(?:schema|type)\z/;
    return 1 if $node->{selections} && _selects_introspection($node->{selections});
  }
  return 0;
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

  # decode_base64 alone is lenient (it skips illegal characters and
  # tolerates bad padding), so an arbitrary string could decode to
  # something that merely looks like a key. Only canonical base64 is a
  # cursor: the alphabet and length must fit, and re-encoding must give
  # the input back byte for byte.
  die client_error "DBIO::GraphQL: invalid cursor\n"
    unless $cursor =~ m{\A[A-Za-z0-9+/]*={0,2}\z}
        && length($cursor) % 4 == 0;
  my $raw = decode_base64($cursor);
  die client_error "DBIO::GraphQL: invalid cursor\n"
    unless encode_base64($raw, '') eq $cursor;

  # The empty raw string is one empty component (a single-column key
  # whose value is ''), not zero components; split would drop it.
  return ('') if $raw eq '';

  # Limit -1 keeps empty trailing components ('x:' is ('x', '')).
  return map { (my $v = $_) =~ s/%3A/:/gi; $v =~ s/%25/%/g; $v }
         split /:/, $raw, -1;
}

# _apply_pagination($rs, $args, $source)
#
# Applies ordering, then either offset (page) or cursor (cursor) pagination.
# Returns ($nodes, $next_cursor, $has_next).
#
# Precedence: cursor pagination wins if both are supplied.
sub _apply_pagination {
  my ($rs, $args, $source, $policy) = @_;

  my @pk_cols = $source->primary_columns;

  # Default: stable order by PK
  my $order = [ map { { -asc => $_ } } @pk_cols ];

  my $order_by = $args->{orderBy};
  if ($order_by && $order_by->{field}) {
    my $field = $order_by->{field};
    unless ($source->has_column($field)
            && !$policy->hidden($source->source_name, $field)) {
      die client_error "DBIO::GraphQL: unknown order column '$field' on source '"
        . $source->source_name . "'\n";
    }
    my $dir = lc($order_by->{direction} // 'ASC');
    if ($args->{cursor}) {
      # A cursor names a position in ascending primary-key order and in no
      # other: under any other order nextCursor does not lead to the next
      # page. An orderBy that asks for that order leaves the default in
      # place; everything else is refused.
      unless (@pk_cols && $field eq $pk_cols[0] && $dir eq 'asc') {
        die client_error "DBIO::GraphQL: cursor pagination on source '"
          . $source->source_name . "' runs in ascending primary-key order"
          . " only, not orderBy '$field' " . uc($dir)
          . "; use page for other orderings\n";
      }
    }
    else {
      $order = { "-$dir" => $field };
    }
  }
  $rs = $rs->search(undef, { order_by => $order });

  if (my $cursor_args = $args->{cursor}) {
    my $first = $cursor_args->{first} // 10;
    my $after = $cursor_args->{after};

    die client_error "DBIO::GraphQL: cursor pagination requires a primary key, but source '"
      . $source->source_name . "' has none; use page pagination\n"
      unless @pk_cols;
    die client_error "DBIO::GraphQL: cursor 'first' must be >= 1 (got $first)\n"
      if $first < 1;

    if (defined $after) {
      my @decoded = _decode_cursor($after);
      unless (@decoded == @pk_cols) {
        die client_error "DBIO::GraphQL: cursor does not match the primary key of source '"
          . $source->source_name . "' (" . scalar(@pk_cols)
          . " column(s), cursor carries " . scalar(@decoded) . " value(s))\n";
      }
      # Row-wise "key > cursor": one branch per column, with every column
      # before it equal and that column greater.
      $rs = $rs->search({ -or => [
        map {
          my $i = $_;
          +{
            (map { $pk_cols[$_] => $decoded[$_] } 0 .. $i - 1),
            $pk_cols[$i] => { '>' => $decoded[$i] },
          }
        } 0 .. $#pk_cols
      ] });
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
    die client_error "DBIO::GraphQL: page 'take' must be >= 1 (got $take)\n" if $take < 1;
    die client_error "DBIO::GraphQL: page 'skip' must be >= 0 (got $skip)\n"  if $skip < 0;
    my @rows = $rs->search(undef, { rows => $take + 1, offset => $skip })->all;
    my $has_next = @rows > $take;
    @rows = @rows[0 .. $take - 1] if $has_next;
    return (
      [ map { { $_->get_columns } } @rows ],
      undef,
      $has_next ? 1 : 0,
    );
  }

  # No page and no cursor: default_rows, one more to learn whether rows remain.
  my $limit = $policy->default_rows;
  my @rows  = $rs->search(undef, { rows => $limit + 1 })->all;
  my $has_next = @rows > $limit;
  @rows = @rows[0 .. $limit - 1] if $has_next;
  return (
    [ map { { $_->get_columns } } @rows ],
    undef,
    $has_next ? 1 : 0,
  );
}

# take, first and skip are bounded by max_rows; an excess is an error, checked
# before any SQL runs.
sub _check_max_rows {
  my ($policy, $args) = @_;
  my %given = (
    take  => ($args->{page}   || {})->{take},
    skip  => ($args->{page}   || {})->{skip},
    first => ($args->{cursor} || {})->{first},
  );
  for my $what (sort keys %given) {
    my $value = $given{$what};
    die client_error "DBIO::GraphQL: $what $value exceeds max_rows (" . $policy->max_rows . ")\n"
      if defined $value && $value > $policy->max_rows;
  }
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::GraphQL - Auto-generate a GraphQL schema from a DBIO schema

=head1 VERSION

version 0.900004

=head1 SYNOPSIS

  use DBIO::GraphQL;

  my $db     = My::Schema->connect(...);
  my $result = DBIO::GraphQL->to_graphql($db,
    except    => [qw(AuditLog)],                    # leave a source out
    hide      => { User => [qw(password_hash)] },   # no field, filter, order, argument
    readonly  => { User => [qw(is_admin tenant_id)] }, # readable, never written
    mutations => [qw(Book)],                        # mutations are opt-in
    authorize => sub {
      my ($op, $moniker, $args, $context, $relationship) = @_;
      return { tenant_id => $context->{tenant} };   # restrict to one tenant
    },
    introspection => 0,
    default_rows  => 100,                           # rows without page/cursor
    max_rows      => 1000,                          # ceiling for take, first, skip
    max_in        => 500,                           # ceiling for an in-list
    max_depth     => 10,                            # selection depth after unfolding
    max_cost      => 10000,                         # fields x rows a query may cost
  );

  # Simple plural query
  $result->{execute}->(
    '{ allBooks { total nodes { title } } }',
    undef, $result->{context});

  # Filtered + paginated + ordered (nested-DBIO-style filter)
  $result->{execute}->('
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
  $result->{execute}->('
    query($after: String) {
      allBooks(cursor: { after: $after, first: 5 }) {
        total
        nextCursor
        hasNextPage
        nodes { id title }
      }
    }', undef, $result->{context}, { after => $cursor });

  # Mutation
  $result->{execute}->(
    'mutation { createBook(title: "Dune", author_id: 4) { id title } }',
    undef, $result->{context});

=head1 DESCRIPTION

B<Trust model.> Without an authorization layer of its own in front of it,
the generated API is full access to what C<to_graphql> releases: every
source and column it is given is readable and filterable by any client
that can send a query, and a mutation writes what the client sends. What
leaves the boundary is chosen by the caller of C<to_graphql> through its
options (see L</to_graphql>): the sources, the hidden and the readonly
columns, the sources that get mutations, the C<authorize> hook that runs
before every resolver that touches the database, and introspection.
Anything not chosen there is exposed.

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
C<deleteX> entry points for every source that opted in with the
C<mutations> option (see L<DBIO::GraphQL::Mutation>); without that option
the schema has no C<Mutation> type. A source without a primary key gets
only C<createX> and its plural query: no singular query, no C<updateX>,
no C<deleteX>.

=back

Composite primary keys are fully supported throughout.

=head1 METHODS

=head2 to_graphql

  my $result = DBIO::GraphQL->to_graphql($db, %options);

Class method. Accepts a connected L<DBIO::Schema> instance and the
options below. Returns a hashref:

  {
    execute       => sub { ... },       # the entry point, see below
    schema        => $graphql_schema,   # GraphQL::Schema
    context       => $db,               # the original schema: pass it as context
    introspection => 1,                 # the introspection option, see check_document
  }

B<Run queries through C<execute>.> It takes the arguments of
C<GraphQL::Execution::execute> without the schema:

  my $response = $result->{execute}->($query, $root, $context, \%variables, $operation);

C<execute> checks the document before the engine runs it, and an error
comes before the first SQL: fragment cycles are refused, the selection
depth after unfolding fragments must not exceed C<max_depth>, the cost must
not exceed C<max_cost>, and a document that selects C<__schema> or
C<__type> is refused when C<introspection> is off. A refused document
answers C<< { errors => [ { message => ... } ] } >>. The depth, the cost and
the upper bounds of the result sets (C<default_rows>, C<max_rows>,
C<max_in>) together bound the work of one request, and that holds for
C<execute>. Executing C<schema> directly with C<GraphQL::Execution> skips
the document check: the relationship resolvers still bound the depth at
run time, but fragment cycles, the cost and C<introspection> are not
checked there.

An unknown option, a source or column the options name that does not
exist, and C<sources> together with C<except> die.

=over 4

=item sources / except

  sources => [qw(Author Book)]
  except  => [qw(AuditLog)]

C<sources> lists the sources to expose, C<except> the ones to leave out;
both together die. A source that is left out disappears entirely: no
type, no queries, no mutations, and no relationship field of another
source that points at it.

=item hide

  hide => { User => [qw(password_hash)] }

Takes the columns out of the schema, the filters, the ordering and the
mutations. A column declared C<< is_serializable => 0 >> is hidden
without being named. A hidden primary-key column is no field, filter or
ordering either, but stays usable as the identity of the singular query,
C<updateX> and C<deleteX>.

=item readonly

  readonly => { User => [qw(is_admin tenant_id)] }

The columns stay readable but are no argument of C<createX> or
C<updateX>, and a unique-constraint column that is readonly does not
identify a row either. Primary-key columns stay the identity of the
singular query, C<updateX> and C<deleteX>; C<readonly> on one forbids only
setting it on C<createX>.

=item mutations

  mutations => 1
  mutations => [qw(Book)]

Mutations are opt-in: C<1> for every exposed source, a list for those
sources only. Without the option the schema has no C<Mutation> type.

=item authorize

  authorize => sub {
    my ($op, $moniker, $args, $context, $relationship) = @_;
    ...
  }

Runs before every resolver that touches the database: root queries,
mutations, relationship fields and the count of a plural query.
C<$op> is C<get>, C<list>, C<create>, C<update>, C<delete> or
C<relationship>; for C<relationship> C<$moniker> is the target source
and C<$relationship> the name of the relation. C<$context> is the
context given to C<execute>. The answer decides:

=over 4

=item * false: the field fails with C<not authorized>, before any SQL.

=item * true: allowed.

=item * a hashref: allowed with a restriction. For C<get>, C<list> and
C<relationship> it is ANDed into the search, also for the C<total>; the
lookup of the related rows happens only within it. For C<updateX> and
C<deleteX> it stands in the writing statement itself, so a row outside it
is not touched: C<updateX> reports "not found", C<deleteX> returns
C<false>. For C<createX> its equality values are set as column values, and
a different value from the client dies; a restriction value that is not
plain (an operator hash) cannot be applied to a create and dies.

=back

=item on_error

  on_error => sub {
    my ($exception, $correlation_id) = @_;
    ...
  }

Every resolver runs inside an error envelope. An error that
C<DBIO::GraphQL> words for the client itself (validation, bounds,
C<not authorized>) reaches the client as it is. A refusal by the database
(L<DBIO::Exception::Server>) is classified by its SQLSTATE and answered with
a fixed message and a code in C<extensions.code>: C<UNIQUE_VIOLATION>
(C<23505>), C<FOREIGN_KEY_VIOLATION> (C<23503>), C<NOT_NULL_VIOLATION>
(C<23502>) or C<CHECK_VIOLATION> (C<23514>). Every other failure is
C<INTERNAL_ERROR> with the message C<internal error> and a
C<extensions.correlation_id>. The statement, bind values, constraint names,
file paths and stack traces never reach the client.

The hook receives the original exception and the correlation id of every
C<INTERNAL_ERROR>; it is the one place the original text goes (to a log, for
instance). Without the hook the correlation id and the original text are
written with C<warn>. The option is a code reference.

=item introspection

  introspection => 0

Switches C<__schema> and C<__type> off (default on). The engine resolves
them itself and offers no switch, so the option is enforced on the document
by the C<execute> code reference of the result (see L</check_document>).

=item default_rows / max_rows / max_in

  default_rows => 100
  max_rows     => 1000
  max_in       => 500

Every result set has an upper bound. Each option is a positive integer,
and C<default_rows> must not exceed C<max_rows>: C<to_graphql> dies naming
both values otherwise.

C<default_rows> (default 100) is the number of rows a plural query returns
without C<page> or C<cursor>, and the most a C<has_many> relationship field
returns; C<hasNextPage> of a plural query says whether rows remain beyond
it. C<max_rows> (default 1000) bounds C<take>, C<first> and C<skip>; a
larger value is an error before any SQL, the rows are not cut silently.
C<max_in> (default 500) bounds the number of values of an C<in> filter,
also inside C<AND> / C<OR>; a longer list is an error before any SQL.

=item max_depth / max_cost

  max_depth => 10
  max_cost  => 10000

Each option is a positive integer; both are enforced by C<execute> before
any SQL.

C<max_depth> (default 10) is the depth of the selection after fragments are
unfolded: a root field is at depth 1, its sub-fields at depth 2, and so on
(C<nodes> of a plural query counts as a level). A deeper selection is an
error. The relationship resolvers check the same depth at run time against
the path of the field being resolved.

C<max_cost> (default 10000) bounds the cost of the operation: every field
costs 1, each alias on its own, and a fragment costs what its fields cost
at every spread. A field that yields rows multiplies the cost of what is
below it by the number of rows it yields: a plural query (C<allXs>, with
its connection object) by its page size (C<page.take>, C<cursor.first>,
variables and their defaults resolved, otherwise C<default_rows>), a
C<has_many> relationship field by C<default_rows>. So
C<{ allBooks { total nodes { id } } }> costs 1 + 100 * 3 = 301 at the
defaults; a full C<max_rows> page with a few fields and a C<has_many> level
of C<default_rows> times C<default_rows> rows fit into the default budget. Fragment cycles are always an error.

=back

=head2 check_document

  DBIO::GraphQL->check_document($result, $query);

Dies when the result was built with C<< introspection => 0 >> and the
query document selects C<__schema> or C<__type>, anywhere in it
(fragments and aliases included). A document that does not parse passes,
the engine reports that error itself. The engine resolves the two meta
fields on its own and offers no switch, so the check runs on the document
before the engine does: the C<execute> code reference of the result runs
it. Executing C<schema> directly does not enforce C<introspection>.

=head1 SCALAR TYPE MAPPING

SQL column types are mapped to GraphQL scalars in the following priority order:

  Boolean: bool, boolean, tinyint(1)
  Float  : float, double, double precision, real
  Int    : int, integer, smallint, tinyint, mediumint, serial
  String : everything else, among them bigint, bigserial, decimal,
           numeric and money (safe fallback)

C<Int> is GraphQL's 32-bit signed integer, C<Float> a double: a column
whose values do not fit either travels as C<String>, in arguments, filters
and output, and reaches the database as the exact text.

The mapping is centralised in L<DBIO::GraphQL::ScalarMap> and reused by
the filter, mutation, and relationship modules.

=head1 PLURAL QUERIES

Every source C<X> gets an C<allXs> query returning an C<XConnection>:

  type XConnection {
    nodes:       [X]
    total:       Int        # total rows matching filter, before pagination;
                            # the COUNT runs only when total is selected
    nextCursor:  String     # opaque cursor; set only during cursor pagination
    hasNextPage: Boolean    # true when rows remain after this page (page or cursor)
  }

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

C<skip> defaults to 0, C<take> defaults to 10. A C<take> below 1 or a
C<skip> below 0 is an error, and so is a C<take> or C<skip> above
C<max_rows>. Without C<page> and C<cursor> a plural query returns the
first C<default_rows> rows.

=head2 Cursor pagination

  # First page
  allBooks(cursor: { first: 5 }) {
    total nextCursor hasNextPage nodes { title }
  }

  # Subsequent pages - pass nextCursor from the previous response
  allBooks(cursor: { after: "...", first: 5 }) {
    total nextCursor hasNextPage nodes { title }
  }

C<first> defaults to 10 and may not exceed C<max_rows>. Cursor pagination takes precedence over
offset pagination if both are supplied in the same query. Cursors are
opaque base64-encoded strings derived from the row's primary key and
should be treated as implementation details subject to change.

Cursor pagination always runs in ascending order of the complete
primary key. A composite key is compared as a whole, so following
C<nextCursor> until C<hasNextPage> is false delivers every matching row
exactly once.

Because a cursor is a position in that order, an C<orderBy> is accepted
next to C<cursor> only when it asks for the same order: C<field> is the
first primary-key column and C<direction> is C<ASC> or omitted. The
rows still come in the order of the complete primary key. Any other
C<orderBy> - C<DESC>, a column outside the primary key, a later
primary-key column - is an error; use offset pagination (C<page>) for
those. A cursor that does not carry one value per primary-key column,
such as one obtained from a different source, is an error as well, and
so is a string that is not a cursor as C<nextCursor> issues it (it must
be canonical base64). C<first> below 1 is an error. A source without a
primary key cannot be paginated by cursor; use C<page> there. An empty
C<after> string is a cursor like any other (the cursor of the key
C<''>), not "no cursor".

=head1 MUTATIONS

For every source C<X> that opted in with the C<mutations> option, three
mutations are generated by L<DBIO::GraphQL::Mutation>:

=head2 createX

  mutation { createBook(title: "Dune", author_id: 4) { id title } }

Accepts the column values as arguments, except hidden and readonly
columns. Columns that are non-nullable,
have no declared default, and are not auto-increment are wrapped in
C<NonNull> and must be supplied. On failure, C<die>s - the error
appears in the top-level C<errors> array of the response.

=head2 updateX

  mutation { updateBook(id: 1, title: "Dune Messiah") { id title } }

Identifies the target row by its primary key B<or> by the complete set
of columns of one unique constraint declared on the source. The key
rule:

=over 4

=item * A complete primary key alone decides. Unique-constraint columns
passed alongside are values to write, never a second way to find a row,
and an unknown primary key is "not found" - there is no fallback to a
unique constraint.

=item * Without a complete primary key, exactly one complete unique
constraint identifies the row. Two complete constraints supplied
together, or a partial primary key beside a constraint, are rejected
with an error instead of guessing which one is meant.

=item * A partial primary key without a complete constraint names no
row: "not found".

=back

Consequence: the value of a unique column can only be changed through
the primary key, because supplying it beside another complete constraint
is rejected and supplying it beside the primary key makes it data.

All non-key columns are optional: only the columns you pass with a
non-null value are written, omitted columns keep their current value
(sparse update). C<die>s if the row cannot be found or the update
fails. A column cannot be set to C<NULL> through C<updateX>, because a
null or omitted argument is ignored.

Sources without a primary key get no C<updateX>.

=head2 deleteX

  mutation { deleteBook(id: 1) }

Identifies the target row by primary key or unique constraint under
the key rule of L</updateX>: a complete primary key alone decides and
an unknown one deletes nothing; without it exactly one complete unique
constraint decides; several complete constraints, or a partial primary
key beside one, are an error. Sources without a primary key get no
C<deleteX>. Returns C<true> (C<Boolean>) on success, C<false> if the row is not
found. A DELETE the database rejects (for example a foreign-key
violation) C<die>s, see L</ERROR HANDLING>.

=head1 ERROR HANDLING

=over 4

=item *

A document C<execute> refuses (fragment cycle, C<max_depth>, C<max_cost>,
introspection switched off) answers with an C<errors> list and no C<data>,
before any SQL.

=back

=over 4

=item *

C<createX>, C<updateX> and C<deleteX> resolver failures C<die>. GraphQL
catches the exception and surfaces it in the top-level C<errors> array,
after the error envelope of the C<on_error> option has classified it; the
C<data> field for the failed mutation will be C<null>.

=item *

C<deleteX> returns C<false> when no row matches the supplied key(s);
a failing DELETE C<die>s.

=item *

Relationship resolution C<die>s at build time when the DBIO
relationship contract is incomplete (see
L<DBIO::GraphQL::Relationship>). C<to_graphql> always builds its
relationship resolver in the default C<die> mode. Only a
L<DBIO::GraphQL::Relationship> constructed directly with
C<< on_error => 'warn' >> downgrades the failure to a warning and skips
the field; C<to_graphql> offers no way to pass that option.

=back

=head1 LIMITATIONS

=over 4

=item * B<Relationship fields are unfiltered.> Relationship fields
within a query (e.g. C<author { books { title } }>) return all
related rows, a C<has_many> field at most C<default_rows> of them. They
do not accept C<filter>, C<orderBy>, or pagination arguments.

=item * B<No nested input for mutations.> C<createX> and C<updateX>
accept only scalar column values. Related rows must be created or
linked separately using their own mutations and raw foreign-key
values.

=item * B<updateX cannot set a column to NULL.> Non-key columns are
optional and only non-null arguments are written, so a column can be
changed but not cleared.

=item * B<Cursor pagination runs in primary-key order only.> The
C<after> cursor encodes the primary key of the last returned row
and continues with the rows whose key is greater. Combining C<cursor>
with an C<orderBy> that is not the ascending primary-key order is
rejected with an error rather than served in an order the cursor
cannot follow. Use offset pagination (C<page>) for descending order
and for ordering by other columns (see L</Cursor pagination>).

=item * B<No custom scalars.> Column types such as C<date>,
C<datetime>, C<json>, and C<uuid> all map to C<String>. Custom
GraphQL scalars are not generated.

=item * B<No subscriptions.> Only C<Query> and C<Mutation> operation
types are generated.

=item * B<String filter case sensitivity is database-dependent.> The
C<like>, C<contains>, C<startsWith> and C<endsWith> operators all run an
SQL C<LIKE>. SQLite C<LIKE> is case-insensitive for ASCII characters but
case-sensitive for Unicode. PostgreSQL C<LIKE> is always case-sensitive.

=back

=head1 ARCHITECTURE

L<DBIO::GraphQL> is a thin orchestrator over focused modules:

=over 4

=item * L<DBIO::GraphQL::ScalarMap> - column data_type → GraphQL scalar

=item * L<DBIO::GraphQL::Filter> (and L<DBIO::GraphQL::Filter::Search>,
L<DBIO::GraphQL::Filter::Null>) - per-source GraphQL InputObject
translating nested filter args into DBIO search conditions

=item * L<DBIO::GraphQL::Relationship> - relationship field
resolution with strict contract validation

=item * L<DBIO::GraphQL::Mutation> - createX / updateX / deleteX
per source

=item * L<DBIO::GraphQL::Policy> - the trust model: exposed sources,
hidden and readonly columns, opt-in mutations, the C<authorize> hook

=item * L<DBIO::GraphQL::Limits> - the document check behind C<execute>:
fragment cycles, depth and cost

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
