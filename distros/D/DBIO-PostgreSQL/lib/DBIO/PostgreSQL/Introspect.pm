package DBIO::PostgreSQL::Introspect;
# ABSTRACT: Introspect a PostgreSQL database via pg_catalog

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::Introspect::Base';

use Scalar::Util ();
use DBIO::PostgreSQL::Util ();


use DBIO::PostgreSQL::Introspect::Schemas;
use DBIO::PostgreSQL::Introspect::Tables;
use DBIO::PostgreSQL::Introspect::Columns;
use DBIO::PostgreSQL::Introspect::Types;
use DBIO::PostgreSQL::Introspect::Indexes;
use DBIO::PostgreSQL::Introspect::Triggers;
use DBIO::PostgreSQL::Introspect::Functions;
use DBIO::PostgreSQL::Introspect::Extensions;
use DBIO::PostgreSQL::Introspect::Policies;
use DBIO::PostgreSQL::Introspect::Sequences;
use DBIO::PostgreSQL::Introspect::OutsideReaders;
use DBIO::PostgreSQL::Introspect::OutsideDependents;
use DBIO::PostgreSQL::Introspect::ForeignKeys;
use DBIO::PostgreSQL::Introspect::CheckConstraints;
use DBIO::PostgreSQL::Introspect::Normalize;

sub schema_filter { $_[0]->{schema_filter} }
sub preserve_case { $_[0]->{preserve_case} // 0 }
sub qualified_names { exists $_[0]->{qualified_names} ? ($_[0]->{qualified_names} ? 1 : 0) : 1 }


sub _build_model {
  my ($self) = @_;
  return $self->_read_sections unless $self->qualified_names;
  return $self->under_empty_search_path($self->dbh, sub { $self->_read_sections });
}

sub _read_sections {
  my ($self) = @_;
  my $dbh = $self->dbh;
  my $filter = $self->schema_filter;

  # model key => Introspect::Section class name.
  # Sections with filtered => 0 are fetched without the schema filter
  # (extensions are cluster-wide, not bound to a single schema).
  my %SECTIONS = (
    schemas           => ['Schemas',           1],
    extensions        => ['Extensions',        0],
    types             => ['Types',             1],
    tables            => ['Tables',            1],
    columns           => ['Columns',           1],
    indexes           => ['Indexes',           1],
    triggers          => ['Triggers',          1],
    functions         => ['Functions',         1],
    policies          => ['Policies',          1],
    sequences         => ['Sequences',         1],
    outside_readers   => ['OutsideReaders',    1],
    outside_dependents => ['OutsideDependents', 1],
    foreign_keys      => ['ForeignKeys',       1],
    check_constraints => ['CheckConstraints',  1],
  );

  my %model;
  for my $key (sort keys %SECTIONS) {
    my ($class, $filtered) = @{ $SECTIONS{$key} };
    my $pkg = "DBIO::PostgreSQL::Introspect::$class";
    $model{$key} = $pkg->fetch($dbh, $filtered ? $filter : ());
  }
  return \%model;
}


sub table_keys {
  my ($self) = @_;
  my $model = $self->model;
  return [
    sort grep { $self->_include_table($_) }
    keys %{ $model->{tables} || {} }
  ];
}

sub _include_table {
  my ($self, $table_key) = @_;
  my ($schema) = split /\./, $table_key, 2;
  my $filter = $self->schema_filter;
  return 1 unless $filter && @$filter;
  return 1 if grep { $_ eq '%' } @$filter;
  return scalar grep { $_ eq $schema } @$filter;
}

sub _normalize_name {
  return DBIO::PostgreSQL::Introspect::Normalize->name(@_[1..$#_], $_[0]->preserve_case);
}


sub identity_kind {
  my ($class, $id) = @_;
  return 'ALWAYS'     if defined $id && $id eq 'a';
  return 'BY DEFAULT' if defined $id && $id eq 'd';
  return undef;
}


sub generated_kind {
  my ($class, $generated) = @_;
  return undef unless defined $generated && length $generated;
  return 'STORED'  if $generated eq 's';
  return 'VIRTUAL' if $generated eq 'v';
  die "attgenerated '$generated' is a kind of generated column this version of "
    . "DBIO::PostgreSQL does not know\n";
}


sub qualified_key {
  my ($class, $a, $b) = @_;

  # Two-arg form: ($schema, $name).
  if (ref $a eq '') {
    return "$a.$b";
  }

  # Hashref form: pull schema + the first matching name field.
  my $schema = $a->{schema_name};
  my $name   = $a->{table_name}
            // $a->{type_name}
            // $a->{function_name}
            // $a->{sequence_name}
            // $a->{index_name}
            // $a->{policy_name};
  return "$schema.$name";
}


sub key_names {
  my ($class, $key, $field, @entries) = @_;

  for my $entry (@entries) {
    # reftype, not ref: a diff operation hands in itself, a blessed hash.
    next unless (Scalar::Util::reftype($entry) // '') eq 'HASH';
    my ($schema, $name) = @{$entry}{ 'schema_name', $field };
    return ($schema, $name)
      if defined $schema && length $schema && defined $name && length $name;
  }

  return split /\./, $key, 2;
}


# The handles a call is running for, by address.
my %UNDER_EMPTY_SEARCH_PATH;

sub under_empty_search_path {
  my ($class, $dbh, $code) = @_;

  my $handle = Scalar::Util::refaddr($dbh);
  return $code->() if $UNDER_EMPTY_SEARCH_PATH{$handle};
  local $UNDER_EMPTY_SEARCH_PATH{$handle} = 1;

  # Without it a statement that fails is passed over, the one that empties
  # the search_path among them.
  local $dbh->{RaiseError} = 1;

  # A transaction of the caller's. DBI knows of one it has begun itself
  # (AutoCommit is off then, sent to the server or not); of a BEGIN that was
  # sent as a statement only the server knows, and ping says so.
  my $savepoint = !$dbh->{AutoCommit} || $dbh->ping == 3;

  if ($savepoint) { $dbh->do('SAVEPOINT dbio_pg_introspect') }
  else            { $dbh->begin_work }

  my $result;
  my $ran = eval {
    $dbh->do(q{SELECT pg_catalog.set_config('search_path', '', true)});
    $result = $code->();
    1;
  };
  my $error = $@;

  my $undone = eval {
    if ($savepoint) {
      $dbh->do('ROLLBACK TO SAVEPOINT dbio_pg_introspect');
      $dbh->do('RELEASE SAVEPOINT dbio_pg_introspect');
    }
    else {
      $dbh->rollback;
    }
    1;
  };
  my $undo_error = $@;

  # The error worth reporting is the first one.
  die $error unless $ran;
  die $undo_error unless $undone;

  return $result;
}


sub system_schema_filter {
  my ($class, $alias) = @_;
  $alias //= 'n';
  return "AND $alias.nspname !~ '^pg_'\n      AND $alias.nspname != 'information_schema'";
}


sub extension_member_filter {
  my ($class, $catalog, $oid) = @_;
  return "\n      AND NOT EXISTS (\n"
       . "        SELECT 1 FROM pg_catalog.pg_depend ext_dep\n"
       . "        WHERE ext_dep.classid = 'pg_catalog.$catalog'::pg_catalog.regclass\n"
       . "          AND ext_dep.objid = $oid\n"
       . "          AND ext_dep.deptype = 'e'\n"
       . "      )";
}


sub internal_part_filter {
  my ($class, $catalog, $oid) = @_;
  return "\n      AND NOT EXISTS (\n"
       . "        SELECT 1 FROM pg_catalog.pg_depend int_dep\n"
       . "        WHERE int_dep.classid = 'pg_catalog.$catalog'::pg_catalog.regclass\n"
       . "          AND int_dep.objid = $oid\n"
       . "          AND int_dep.objsubid = 0\n"
       . "          AND int_dep.deptype = 'i'\n"
       . "      )";
}


sub column_reads {
  my ($class, $dbh, $filter, $catalog, $relation, $name, $where) = @_;

  my $sql = qq{
    SELECT DISTINCT
      n.nspname AS schema_name,
      c.relname AS table_name,
      o.$name AS object_name,
      rn.nspname AS ref_schema,
      r.relname AS ref_name,
      a.attname AS ref_column
    FROM pg_catalog.$catalog o
    JOIN pg_catalog.pg_class c ON c.oid = o.$relation
    JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
    JOIN pg_catalog.pg_depend d
      ON d.classid = 'pg_catalog.$catalog'::pg_catalog.regclass
     AND d.objid = o.oid
     AND d.refclassid = 'pg_catalog.pg_class'::pg_catalog.regclass
     AND d.refobjsubid > 0
    JOIN pg_catalog.pg_class r ON r.oid = d.refobjid
    JOIN pg_catalog.pg_namespace rn ON rn.oid = r.relnamespace
    JOIN pg_catalog.pg_attribute a ON a.attrelid = d.refobjid AND a.attnum = d.refobjsubid
    WHERE 1=1
  };
  $sql .= "\n      AND $where" if defined $where;
  $sql .= "\n      " . $class->system_schema_filter('n');
  $sql .= $class->extension_member_filter('pg_class', 'c.oid');

  my @bind;
  if ($filter && @$filter) {
    $sql .= ' AND n.nspname = ANY($1)';
    push @bind, $filter;
  }

  my $sth = $dbh->prepare($sql);
  $sth->execute(@bind);

  my %reads;
  while (my $row = $sth->fetchrow_hashref) {
    my $on   = $class->qualified_key($row);
    my $read = $class->qualified_key(@{$row}{qw( ref_schema ref_name )});
    push @{ $reads{$on}{ $row->{object_name} }{$read} }, $row->{ref_column};
  }
  for my $objects (values %reads) {
    for my $object (values %$objects) {
      $_ = [ sort @$_ ] for values %$object;
    }
  }

  return \%reads;
}

sub _normalize_data_type {
  my ($self, $info, $column) = @_;

  # Enum columns need the value list from the model, which is the only
  # stateful piece of the normalization. Resolve it here so the leaf
  # helper stays pure.
  my $enum_values;
  if ($column->{type_category} && $column->{type_category} eq 'e' && $column->{enum_type}) {
    my $ts = $column->{type_schema} || '';
    my $qualified = $ts ne 'public' ? "$ts.$column->{enum_type}" : $column->{enum_type};
    my $type_info = $self->model->{types}{$qualified}
      || $self->model->{types}{ "$ts.$column->{enum_type}" };
    $enum_values = $type_info->{values} if $type_info;
  }

  return DBIO::PostgreSQL::Introspect::Normalize->data_type($info, $column, $enum_values);
}

sub _normalize_default_value {
  return DBIO::PostgreSQL::Introspect::Normalize->default_value(@_[1..$#_]);
}


sub normalize_array {
  return DBIO::PostgreSQL::Introspect::Normalize->array($_[1]);
}


sub table_columns {
  my ($self, $table_key) = @_;
  return [
    map { $self->_normalize_name($_->{column_name}) }
    sort { $a->{ordinal} <=> $b->{ordinal} }
    @{ $self->model->{columns}{$table_key} || [] }
  ];
}


sub table_columns_info {
  my ($self, $table_key) = @_;

  $self->{_table_columns_info_cache} //= {};
  my $cached = $self->{_table_columns_info_cache}{$table_key};
  return { %$cached } if $cached;

  my %pk = map { $_ => 1 } @{ $self->table_pk_info($table_key) };
  my %columns;

  for my $column (
    sort { $a->{ordinal} <=> $b->{ordinal} }
    @{ $self->model->{columns}{$table_key} || [] }
  ) {
    my $name = $self->_normalize_name($column->{column_name});
    my $info = {
      # karr k49 / core k126: fold the primary key into is_nullable the way
      # the core base now does. The PG model carries no is_pk flag on the
      # column -- table_pk_info comes from the indexes section -- so the fold
      # uses the already-resolved %pk set.
      is_nullable => (($column->{not_null} || $pk{$name}) ? 0 : 1),
    };

    $self->_normalize_data_type($info, $column);
    $self->_normalize_default_value($info, $column->{default_value}, $pk{$name});

    if ($column->{identity}) {
      $info->{is_auto_increment} = 1;
      $info->{extra}{identity} = $column->{identity};
      $info->{retrieve_on_insert} = 1 if $pk{$name};
    }

    if ($column->{generated}) {
      $info->{extra}{generated} = $column->{generated};
    }

    $columns{$name} = $info;
  }

  $self->{_table_columns_info_cache}{$table_key} = \%columns;
  return { %columns };
}


sub table_pk_info {
  my ($self, $table_key) = @_;

  my $indexes = $self->model->{indexes}{$table_key} || {};
  for my $name (sort keys %$indexes) {
    my $index = $indexes->{$name};
    next unless $index->{is_primary};
    return [ map { $self->_normalize_name($_) } @{ $index->{columns} || [] } ];
  }

  return [];
}


sub table_uniq_info {
  my ($self, $table_key) = @_;

  my $indexes = $self->model->{indexes}{$table_key} || {};
  my @uniqs;

  for my $name (sort keys %$indexes) {
    my $index = $indexes->{$name};
    next unless $index->{is_unique};
    next if $index->{is_primary};
    next if $index->{predicate};
    next if $index->{expressions};
    next unless @{ $index->{columns} || [] };
    next if ($index->{access_method} || '') ne 'btree';
    # A per-column operator class cannot be expressed as a UNIQUE constraint,
    # so such an index stays an index. Mirrored by $simple_unique in
    # result_class_extra_statements -- change both or the index is emitted
    # twice, as a constraint and as an index (karr k54).
    next if $index->{opclasses} && %{ $index->{opclasses} };

    push @uniqs, [
      $name => [ map { $self->_normalize_name($_) } @{ $index->{columns} } ],
    ];
  }

  return \@uniqs;
}


sub table_fk_info {
  my ($self, $table_key) = @_;

  my @fks = map {
    {
      constraint_name => $_->{constraint_name},
      local_columns   => [ map { $self->_normalize_name($_) } @{ $_->{local_columns} || [] } ],
      remote_columns  => [ map { $self->_normalize_name($_) } @{ $_->{remote_columns} || [] } ],
      remote_schema   => $_->{remote_schema},
      remote_table    => $_->{remote_table},
      attrs           => {
        is_deferrable => $_->{is_deferrable} ? 1 : 0,
        on_delete     => $_->{on_delete},
        on_update     => $_->{on_update},
      },
    }
  } @{ $self->model->{foreign_keys}{$table_key} || [] };

  return \@fks;
}


sub table_is_view {
  my ($self, $table_key) = @_;
  my $table = $self->model->{tables}{$table_key} || {};
  return ($table->{kind} || '') =~ /^(?:v|m)\z/ ? 1 : 0;
}


sub view_definition {
  my ($self, $table_key) = @_;
  my $table = $self->model->{tables}{$table_key} || {};
  my $def = $table->{view_definition};
  return undef unless defined $def;
  $def =~ s/^\s+//;
  $def = DBIO::PostgreSQL::Util::trim_end($def);
  # one closing semicolon, with the whitespace around it
  $def = DBIO::PostgreSQL::Util::trim_end(substr($def, 0, -1))
    if substr($def, -1) eq ';';
  return $def;
}


sub table_comment {
  my ($self, $table_key) = @_;
  return $self->model->{tables}{$table_key}{comment};
}


sub column_comment {
  my ($self, $table_key, $column_name) = @_;

  $self->{_column_comment_cache} //= {};
  unless (exists $self->{_column_comment_cache}{$table_key}) {
    my %cache;
    for my $column (@{ $self->model->{columns}{$table_key} || [] }) {
      $cache{ $self->_normalize_name($column->{column_name}) } = $column->{comment};
    }
    $self->{_column_comment_cache}{$table_key} = \%cache;
  }
  return $self->{_column_comment_cache}{$table_key}{ $self->_normalize_name($column_name) };
}


sub result_class_extra_statements {
  my ($self, $table_key) = @_;

  my ($schema_name, $table_name) = split /\./, $table_key, 2;
  my @stmts;

  push @stmts, [pg_schema => $schema_name]
    if defined $schema_name && length $schema_name;

  my $indexes = $self->model->{indexes}{$table_key} || {};
  my %pg_indexes;
  for my $name (sort keys %$indexes) {
    my $index = $indexes->{$name};
    next if $index->{is_primary};

    # Mirrors table_uniq_info: an index it hands over as a UNIQUE constraint
    # must not also be emitted here. Keep the two conditions in step.
    my $simple_unique = $index->{is_unique}
      && !$index->{predicate}
      && !$index->{expressions}
      && !($index->{opclasses} && %{ $index->{opclasses} })
      && @{ $index->{columns} || [] }
      && ($index->{access_method} || '') eq 'btree';

    next if $simple_unique;

    my %def;
    $def{columns}    = [ map { $self->_normalize_name($_) } @{ $index->{columns} } ]
      if @{ $index->{columns} || [] };
    $def{expression}  = $index->{expressions} if $index->{expressions};
    $def{where}      = $index->{predicate} if $index->{predicate};
    $def{using}      = $index->{access_method}
      if ($index->{access_method} || '') ne 'btree';
    $def{unique}     = 1 if $index->{is_unique};
    $def{include}    = [ map { $self->_normalize_name($_) } @{ $index->{include_columns} } ]
      if @{ $index->{include_columns} || [] };
    $def{with}       = $index->{storage_params}
      if $index->{storage_params} && %{ $index->{storage_params} };

    # Per-column operator classes. Without these an introspected pgvector
    # hnsw index cannot be redeployed at all: hnsw has no default opclass
    # for vector, so CREATE INDEX ... USING hnsw (embedding) is rejected.
    # An ivfflat index would come back with its default, vector_l2_ops,
    # whatever class it had. That default itself never arrives here:
    # pg_get_indexdef does not print it.
    if ($index->{opclasses} && %{ $index->{opclasses} }) {
      my %opclasses;
      for my $column (keys %{ $index->{opclasses} }) {
        $opclasses{ $self->_normalize_name($column) } = $index->{opclasses}{$column};
      }
      $def{opclasses} = \%opclasses;
    }

    $pg_indexes{$name} = \%def if %def;
  }
  for my $name (sort keys %pg_indexes) {
    push @stmts, [pg_index => $name, $pg_indexes{$name}];
  }

  my $triggers = $self->model->{triggers}{$table_key} || {};
  for my $name (sort keys %$triggers) {
    my $trigger = $triggers->{$name};
    my $execute = $trigger->{execute};
    push @stmts, [pg_trigger => $name, {
      when     => $trigger->{timing},
      event    => $trigger->{event},
      for_each => $trigger->{orientation},
      ($execute ? (execute => $execute) : ()),
    }];
  }

  my $table = $self->model->{tables}{$table_key} || {};
  my $policies = $self->model->{policies}{$table_key} || {};
  if ($table->{rls_enabled} || $table->{rls_forced} || keys %$policies) {
    my %defs;
    for my $name (sort keys %$policies) {
      my $policy = $policies->{$name};
      $defs{$name} = {
        for        => $policy->{command} || 'ALL',
        ($policy->{roles} ? (roles => $self->normalize_array($policy->{roles})) : ()),
        ($policy->{using_expr} ? (using => $policy->{using_expr}) : ()),
        ($policy->{check_expr} ? (with_check => $policy->{check_expr}) : ()),
      };
    }
    push @stmts, [pg_rls => {
      enable   => $table->{rls_enabled} ? 1 : 0,
      force    => $table->{rls_forced} ? 1 : 0,
      (keys %defs ? (policies => \%defs) : ()),
    }];
  }

  my $checks = $self->model->{check_constraints}{$table_key} || {};
  for my $name (sort keys %$checks) {
    push @stmts, [pg_check_constraint => $name, $checks->{$name}];
  }

  return @stmts;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::PostgreSQL::Introspect - Introspect a PostgreSQL database via pg_catalog

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

C<DBIO::PostgreSQL::Introspect> reads the live state of a PostgreSQL database
via C<pg_catalog> and returns a unified model hashref. It is the source side
of the test-deploy-and-compare strategy used by L<DBIO::PostgreSQL::Deploy>.

    my $intro = DBIO::PostgreSQL::Introspect->new(
        dbh           => $dbh,
        schema_filter => [qw( public auth api )],
    );
    my $model = $intro->model;
    # $model->{schemas}, $model->{tables}, $model->{columns}, ...

The model is built lazily on first access and covers schemas, extensions,
types (enums/composites/ranges), tables, columns, indexes, triggers,
functions, RLS policies, and sequences, and the views outside the schema filter
that read a column inside it (C<outside_readers>,
L<DBIO::PostgreSQL::Introspect::OutsideReaders>), and what stands outside the filter
on a table, a type or a schema of the model (C<outside_dependents>,
L<DBIO::PostgreSQL::Introspect::OutsideDependents>). What an installed extension owns is
not in it, only the extension itself: see L</extension_member_filter>. Nor is
a function PostgreSQL made as part of another object, such as the
constructors of a range type: see L</internal_part_filter>. The
same model shape is consumed by
L<DBIO::PostgreSQL::Diff> and by the test-deploy workflow in
L<DBIO::PostgreSQL::Deploy>. On top of it, this class implements the
normalized generation contract from L<DBIO::Introspect::Base> so it can act
as a L<DBIO::Generate> source.

=head1 ATTRIBUTES

=head2 schema_filter

Optional ArrayRef of PostgreSQL schema names to restrict introspection to.
When C<undef>, all non-system schemas are introspected.

=head2 qualified_names

    my $intro = DBIO::PostgreSQL::Introspect->new(
        dbh             => $dbh,
        qualified_names => 1,
    );

Whether the whole model is read under an empty C<search_path>
(L</under_empty_search_path>). Default: true.

PostgreSQL does not keep the text of a definition, it writes it for whoever
asks, and writes a name without its schema whenever the C<search_path> of the
asking session finds the object. That goes for every text of the model: a
column type, a composite attribute, a range's subtype and a function's return
type (C<format_type>), a default, an index predicate and expression, a policy
(C<pg_get_expr>), and the definitions of an index, a trigger, a function and
a CHECK constraint, down to the arguments a function is filed under
(C<app.label(s status)> or C<app.label(s app.status)>) and the table a
sequence belongs to. So read under the session's own C<search_path>, the
model of one database is a different text in two sessions, and a text of it
means something else, or nothing, when it is run in a session with another
C<search_path>.

With it, every name outside C<pg_catalog> comes with its schema, one in
C<public> too: C<public.mood>, C<public.vector(3)>,
C<nextval('public.thing_id_seq'::regclass)>, C<EXECUTE FUNCTION
public.touch()>. The model is then the same text whoever asks, and each of
its texts names the same objects wherever it is run. The diff compares these
texts and runs them; L<DBIO::PostgreSQL::Deploy> reads both of its databases
this way, and so does L<DBIO::Generate>
(L<DBIO::PostgreSQL::Introspect::Normalize> takes C<public.vector(3)> apart
as it did C<vector(3)>).

A false value reads under the session's own C<search_path>: the names are as
that session finds them, and the model is comparable only with one read under
the same path. The one text that does not follow the attribute is
C<view_definition>, which is read under an empty C<search_path> in every
model (L<DBIO::PostgreSQL::Introspect::Tables>).

=head2 preserve_case

Whether the methods of the L</NORMALIZED CONTRACT> return column names in the
case the catalog has them. False by default: they are lowercased
(L<DBIO::PostgreSQL::Introspect::Normalize/name>). The native model keeps
every name as the catalog has it either way.

=head1 METHODS

=head2 table_keys

Returns sorted ArrayRef of schema-qualified table keys (C<schema.name>).

=head2 identity_kind

    my $kind = DBIO::PostgreSQL::Introspect->identity_kind($id);

Maps the C<attidentity> opcode from C<pg_catalog.pg_attribute> to the SQL
keyword that follows C<GENERATED> in C<CREATE TABLE>: C<'a'> becomes
C<'ALWAYS'>, C<'d'> becomes C<'BY DEFAULT'>, anything else (including
C<undef> and C<''>) returns C<undef>. The same map is needed by every site
that emits identity syntax (Diff::Column, Diff::Table, DDL).

=head2 generated_kind

    my $kind = DBIO::PostgreSQL::Introspect->generated_kind($generated);

Maps the C<attgenerated> mark from C<pg_catalog.pg_attribute> to the key word
that closes C<GENERATED ALWAYS AS (...)>: C<'s'> becomes C<'STORED'>, C<'v'>
(PostgreSQL 18) becomes C<'VIRTUAL'>; C<undef> and C<''> -- a column that is
not generated -- return C<undef>.

Any other mark dies. For a generated column the catalog keeps the expression
where it keeps a default, so a mark that is passed over turns the column into
an ordinary one with that expression as its C<DEFAULT>.

=head2 qualified_key

    my $key = DBIO::PostgreSQL::Introspect->qualified_key($schema, $name);
    my $key = DBIO::PostgreSQL::Introspect->qualified_key($row);

Builds the canonical C<"schema.name"> key used to index introspected
models. Accepts either two positional args (C<$schema>, C<$name>) or a
single hashref that contains both C<schema_name> and one of C<table_name>,
C<type_name>, C<function_name>, C<sequence_name>, C<index_name>, or
C<policy_name>. Centralising the construction here keeps every section
key in lockstep — if the separator ever changes, only this helper moves.

=head2 key_names

    my ($schema, $name) = DBIO::PostgreSQL::Introspect->key_names(
        $key, table_name => @entries,
    );

The way back from a L</qualified_key>: the names the key stands for, the
schema first.

A key is where a model files an object, not what the object is called. It
cannot be taken apart again -- C<my.schema.tbl> is as much the table C<tbl> in
the schema C<my.schema> as the table C<schema.tbl> in the schema C<my> -- so
the names come from an entry that carries them: the first of C<@entries> that
is a hashref with a C<schema_name> and the field named second (C<table_name>,
C<type_name>, ...). Every entry this introspector files has both, and what it
files under a table's key (an index, a trigger, a policy) names that table.
Entries that are not hashrefs, or lack either name, are passed over.

Only when no entry names the object is the key split, at its first dot. That
is right for every key whose schema name has no dot, and is what a model built
by hand without the names gets. A key without any dot is returned as the one
name it is.

=head2 under_empty_search_path

    my $rows = DBIO::PostgreSQL::Introspect->under_empty_search_path($dbh, sub {
        $dbh->selectall_arrayref($sql);
    });

Runs the code with the C<search_path> of C<$dbh> empty and returns what it
returns (one value). Under an empty C<search_path> PostgreSQL writes every
name outside C<pg_catalog> with its schema -- C<pg_dump> reads definitions
the same way. This is the one place that says how: L</qualified_names> runs
the whole model through it, L<DBIO::PostgreSQL::Introspect::Tables> the view
definitions of a model read without it.

The session is afterwards what it was, whether the code returns or dies. The
C<search_path> is not set and set back: it is set for a transaction that is
then rolled back, and goes with it.

=over 4

=item *

Outside a transaction, one is opened for the code and rolled back.

=item *

Inside a transaction of the caller's -- C<AutoCommit> off, C<begin_work>, or
a C<BEGIN> sent as a statement -- it is a savepoint that is rolled back to
and released. The caller's transaction stays open with everything it did,
also when the code dies: the error is the caller's to handle, the
transaction is not aborted by it. A C<SET LOCAL search_path> of the caller's
is in force again as well, and still ends with the transaction (setting the
value back would have made it the session's).

=back

The code is meant to read. What it changes in the database is rolled back
with the rest.

A call inside the code of another, for the same handle, runs its code where
it stands. C<RaiseError> is on for the handle while the code runs.

=head2 system_schema_filter

    my $sql = DBIO::PostgreSQL::Introspect->system_schema_filter($alias);

Returns a two-line SQL fragment for the C<pg_catalog> namespace filter
that excludes the PostgreSQL reserved namespaces (C<pg_*> and
C<information_schema>). The optional C<$alias> is the alias used in the
query for the C<pg_namespace> row (defaults to C<n>). Every introspect
helper concatenates this fragment into its C<WHERE> clause so the set
of excluded namespaces is centralised.

=head2 extension_member_filter

    my $sql = DBIO::PostgreSQL::Introspect->extension_member_filter('pg_class', 'c.oid');

Returns a SQL fragment for a C<WHERE> clause that leaves out what an installed
extension owns: the rows whose object has a C<pg_depend> entry of deptype
C<e>. C<$catalog> is the C<pg_catalog> table the object lives in (C<pg_class>,
C<pg_type>, C<pg_proc>, C<pg_namespace>), C<$oid> the SQL expression for its
oid in the query.

C<CREATE EXTENSION> / C<DROP EXTENSION> own such objects, so they are not the
schema's to create or drop one by one. Every introspect helper that reads a
kind of object an extension can own appends this fragment after
L</system_schema_filter>. The helpers that read what hangs on a relation
(columns, indexes, constraints, triggers, policies) append it for the
relation's oid: none of those is an extension member in its own right, and
they leave the model together with the relation. So does the sequence behind
a C<serial> or identity column
(L<DBIO::PostgreSQL::Introspect::Sequences>), for which the fragment is
appended a second time, for the oid of the table the sequence belongs to.

=head2 internal_part_filter

    my $sql = DBIO::PostgreSQL::Introspect->internal_part_filter('pg_proc', 'p.oid');

Returns a SQL fragment for a C<WHERE> clause that leaves out what PostgreSQL
made as part of another object: the rows whose object has a C<pg_depend>
entry of deptype C<i> (internal). C<$catalog> and C<$oid> are as for
L</extension_member_filter>.

PostgreSQL's own words for that dependency: the object "was created as part
of creation of the referenced object, and is really just a part of its
internal implementation. A direct C<DROP> of the dependent object will be
disallowed outright". Such an object is not the schema's to create or drop:
it comes and goes with the object it is part of. The constructor functions of
a range type are the case this is here for -- C<CREATE TYPE ... AS RANGE>
makes them, for the range and for its multirange type, C<DROP TYPE> takes
them, and C<DROP FUNCTION> on one fails with C<cannot drop function ...
because type ... requires it>.

L<DBIO::PostgreSQL::Introspect::Functions> appends it. It is not a rule for
every section: an index that carries a C<PRIMARY KEY> or C<UNIQUE> constraint
is an internal part of that constraint by the same deptype, and stays in the
model as the only trace of the constraint the diff has.

=head2 column_reads

    my $reads = DBIO::PostgreSQL::Introspect->column_reads(
        $dbh, $filter, 'pg_policy', 'polrelid', 'polname',
    );
    # { 'public.t' => { p => { 'public.t' => [ 'v' ] } } }

The columns an object that hangs on a relation reads, from the C<pg_depend>
rows PostgreSQL keeps for it (the column is C<refobjsubid>): no text is taken
apart. C<$catalog> is the object's catalog (C<pg_policy>, C<pg_trigger>),
C<$relation> its column for the relation it is on, C<$name> its name column,
and an optional C<$where> a further condition on the object C<o>. The result
is keyed by the key of the relation the object is on, then by the object's
name, and gives for each the relations it reads, by key, with the column names,
sorted. An object that reads no column has no entry. C<$filter> restricts the
relation the object is on, as for every section.

L<DBIO::PostgreSQL::Introspect::Policies> and
L<DBIO::PostgreSQL::Introspect::Triggers> use it, for
C<depends_on_columns>.

=head2 normalize_array

    my $list = DBIO::PostgreSQL::Introspect->normalize_array($value);

A PostgreSQL array as a Perl ArrayRef, in whichever of its two forms the
handle returned it: L<DBIO::PostgreSQL::Introspect::Normalize/array>. The
section classes call it for the arrays their queries return.

=head2 table_columns

    my \@names = $intro->table_columns($key);

Ordered list of column names for C<$key>.

=head2 table_columns_info

    my \%info = %{ $intro->table_columns_info($key) };

Hashref of column metadata.

=head2 table_pk_info

    my \@pk_cols = @{ $intro->table_pk_info($key) };

Ordered list of primary key column names.

=head2 table_uniq_info

    my \@constraints = @{ $intro->table_uniq_info($key) };

List of C<[ $constraint_name, \@col_names ]> pairs.

=head2 table_fk_info

    my \@fks = @{ $intro->table_fk_info($key) };

Each FK is a hashref.

=head2 table_is_view

Returns true if C<$key> is a view.

=head2 view_definition

SQL text of the view definition, or C<undef>.

=head2 table_comment

Comment string for the table, or C<undef>.

=head2 column_comment

Comment string for a column, or C<undef>.

=head2 result_class_extra_statements

    my @stmts = $intro->result_class_extra_statements($key);

Driver-specific PostgreSQL statements for the generated Result class.
Emits pg_schema, pg_index, pg_trigger, pg_rls, pg_check_constraint.

=head1 NORMALIZED CONTRACT

The generation contract defined in L<DBIO::Introspect::Base> is implemented
by L</table_keys>, L</table_columns>, L</table_columns_info>,
L</table_pk_info>, L</table_uniq_info>, L</table_fk_info>, L</table_is_view>,
L</view_definition>, L</table_comment>, L</column_comment> and
L</result_class_extra_statements>. They build on the native model.

The other methods are class methods the native model is built and read with:
the section classes under C<DBIO::PostgreSQL::Introspect::>,
L<DBIO::PostgreSQL::Diff> and L<DBIO::PostgreSQL::DDL> call them.

=head1 SEE ALSO

L<DBIO::PostgreSQL::Deploy>, L<DBIO::PostgreSQL::Diff>.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
