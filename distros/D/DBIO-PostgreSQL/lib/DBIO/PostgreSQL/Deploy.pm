package DBIO::PostgreSQL::Deploy;
# ABSTRACT: Deploy and upgrade PostgreSQL schemas via test-deploy-and-compare

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::Deploy::Base::TempDatabase';

use DBI;
use Hash::Util ();
use Scalar::Util ();
use Storable ();
use Crypt::URandom ();
use DBIO::Exception;
use DBIO::Extension::List ();
use DBIO::PostgreSQL::DDL       ();
use DBIO::PostgreSQL::Extension ();
use DBIO::PostgreSQL::Introspect ();
use DBIO::PostgreSQL::Diff      ();
use DBIO::PostgreSQL::Util ();



sub manage_extensions_when_restricted { $_[0]->{manage_extensions_when_restricted} }


sub foreign_keys_not_valid { $_[0]->{foreign_keys_not_valid} }

# --- class-name hooks for DBIO::Deploy::Base -------------------------------

sub _ddl_class       { 'DBIO::PostgreSQL::DDL'       }
sub _introspect_class { 'DBIO::PostgreSQL::Introspect' }
sub _diff_class      { 'DBIO::PostgreSQL::Diff'      }


sub install_schema {
  my ($self, $schema_name) = @_;
  my $dbh = $self->_dbh;
  $dbh->do(sprintf 'CREATE SCHEMA IF NOT EXISTS %s',
    DBIO::PostgreSQL::Util::quote_ident($schema_name));
  return 1;
}

# --- extension prerequisites -------------------------------------------------


sub install {
  my ($self) = @_;
  $self->_resolve_extension_list;
  $self->_check_extensions_available;
  $self->_extension_control_schemas;
  return $self->SUPER::install;
}


sub _deploy_and_introspect_temp {
  my ($self, $temp_db) = @_;
  $self->_check_extensions_available;
  $self->_check_temp_db_empty($temp_db);
  local $self->{_temp_extension_schemas} = $self->_installed_extension_schemas;
  return $self->SUPER::_deploy_and_introspect_temp($temp_db);
}


sub _check_temp_db_empty {
  my ($self, $temp_db) = @_;
  my ($dsn, $user, $pass) = $self->_temp_connect_info($temp_db);
  my $dbh = eval {
    DBI->connect($dsn, $user, $pass, {
      RaiseError => 1, PrintError => 0, AutoCommit => 1,
    })
  } or die DBIO::Util::mask_connect_secrets(
    $@ || "Cannot connect to temp database: $DBI::errstr", [ $dsn, $user, $pass ],
  );

  my $err;
  eval { $self->_check_database_empty($dbh); 1 } or $err = $@;
  eval { $dbh->disconnect; 1 } or $err ||= $@;
  die $err if $err;
  return;
}


sub _check_database_empty {
  my ($self, $dbh) = @_;
  my $model = $self->_introspect_class->new(
    dbh             => $dbh,
    qualified_names => 1,
  )->model;
  my @found = $self->_foreign_objects($model);
  return unless @found;
  DBIO::Exception->throw(
    'the temporary database is not empty, the target model is only what the schema declares; found: '
    . join(', ', @found));
}


sub _foreign_objects {
  my ($self, $model) = @_;
  my @found;
  for my $kind (
    [ schema    => 'schemas'    ],
    [ extension => 'extensions' ],
    [ type      => 'types'      ],
    [ table     => 'tables'     ],
    [ sequence  => 'sequences'  ],
    [ function  => 'functions'  ],
  ) {
    my ($label, $section) = @$kind;
    for my $name (sort keys %{ $model->{$section} // {} }) {
      next if $section eq 'schemas'    && $name eq 'public';
      next if $section eq 'extensions' && $name eq 'plpgsql';
      push @found, "$label $name";
    }
  }
  return @found;
}


sub _installed_extension_schemas {
  my ($self) = @_;
  my @declared = DBIO::PostgreSQL::DDL::_schema_decl($self->schema, 'pg_extensions')
    or return {};
  my $given     = DBIO::PostgreSQL::DDL::_schema_decl($self->schema, 'pg_extension_schemas') // {};
  my $fixed     = $self->_extension_control_schemas;
  my $namespace = DBIO::PostgreSQL::DDL::_connection_namespace($self->schema);
  my $state     = $self->_installed_extensions(\@declared);
  my %held;
  for my $name (@declared) {
    next if defined $given->{$name} || defined $fixed->{$name};
    my $e = $state->{$name};
    next unless $e && $e->{installed} && defined $e->{schema};
    next if $e->{schema} eq 'public';
    next if defined $namespace && $e->{schema} eq $namespace;
    $held{$name} = $e->{schema};
  }
  return \%held;
}


sub _execute_ddl {
  my ($self, $dbh, @rest) = @_;

  my $storage = $self->_driver_storage;
  if ($storage && $storage->can('_declared_search_path')
      && !defined $storage->connection_schema) {
    my @path = $storage->_declared_search_path;
    # An extension the temporary database holds in a schema of its own
    # (_installed_extension_schemas) is found behind the rest of the path, as
    # the live session finds it; the default path ahead of it when none is
    # declared.
    my %once;
    my @held = sort grep { !$once{$_}++ } values %{ $self->{_temp_extension_schemas} // {} };
    if (@held) {
      @path = ('$user', 'public') unless @path;
      my %seen = map { $_ => 1 } @path;
      push @path, grep { !$seen{$_}++ } @held;
    }
    # Asked last: it connects, and a schema with nothing to set needs none.
    if (@path && Scalar::Util::refaddr($dbh) != (Scalar::Util::refaddr($self->_dbh) // 0)) {
      $dbh->do('SET search_path TO ' . join ', ',
        map { DBIO::PostgreSQL::Util::quote_search_path_entry($_) } @path);
    }
  }

  return $self->SUPER::_execute_ddl($dbh, @rest);
}


sub _extension_control_schemas {
  my ($self) = @_;
  my @declared = DBIO::PostgreSQL::DDL::_schema_decl($self->schema, 'pg_extensions');
  return {} unless @declared;

  my $rows = $self->_dbh->selectall_arrayref(
    DBIO::PostgreSQL::DDL::control_schemas_sql(@declared));
  my %fixed = map { $_->[0] => $_->[1] } @$rows;

  DBIO::PostgreSQL::DDL::check_control_schemas($self->schema, \%fixed);
  return \%fixed;
}


sub _install_ddl {
  my ($self) = @_;
  return $self->_ddl_class->install_ddl($self->schema,
    extension_control_schemas   => $self->_extension_control_schemas,
    extension_installed_schemas => $self->{_temp_extension_schemas} // {});
}


sub _check_extensions_available {
  my ($self) = @_;
  my @declared = DBIO::PostgreSQL::DDL::_schema_decl($self->schema, 'pg_extensions');
  return 1 unless @declared;

  my $dbh = $self->_dbh;
  my $available = $dbh->selectcol_arrayref(
    'SELECT name FROM pg_catalog.pg_available_extensions'
  );
  my %available = map { $_ => 1 } @$available;

  my @missing = grep { !$available{$_} } @declared;
  DBIO::Exception->throw($self->_missing_extension_message(@missing)) if @missing;
  return 1;
}


sub _missing_extension_message {
  my ($class, @missing) = @_;
  my $list = join ', ', map { qq{"$_"} } @missing;
  my $fix  = join "\n",
    map { '  CREATE EXTENSION ' . DBIO::PostgreSQL::Util::quote_ident($_) . ';' } @missing;
  return "Declared PostgreSQL extension(s) not available on this server: $list\n"
       . "Install them on the server (e.g. as a superuser) and retry:\n"
       . "$fix\n"
       . "The deploy needs these extensions to exist before it can create "
       . "extension-backed types (e.g. vector(N) columns).";
}

# --- PostgreSQL-specific overrides -----------------------------------------


sub _new_introspect {
  my ($self, $dbh) = @_;
  return $self->_introspect_class->new(
    dbh             => $dbh,
    schema_filter   => $self->_schema_filter,
    qualified_names => 1,
  );
}


sub _build_target_model {
  my ($self) = @_;
  return $self->_mark_namespace(
    $self->_mark_extension_schemas($self->SUPER::_build_target_model));
}


sub _mark_extension_schemas {
  my ($self, $model) = @_;
  my $declared = DBIO::PostgreSQL::DDL::_schema_decl($self->schema, 'pg_extension_schemas') // {};
  for my $name (keys %$declared) {
    my $entry = $model->{extensions}{$name} or next;
    $entry->{declared_schema} = $declared->{$name};
  }
  my $fixed = $self->_extension_control_schemas;
  my $held  = $self->_installed_extension_schemas;
  my $namespace = DBIO::PostgreSQL::DDL::_connection_namespace($self->schema);
  for my $name (DBIO::PostgreSQL::DDL::_schema_decl($self->schema, 'pg_extensions')) {
    my $entry = $model->{extensions}{$name} or next;
    if (defined $declared->{$name}) {
      $entry->{install_schema} = $declared->{$name};
    }
    elsif (defined $fixed->{$name}) {
      $entry->{control_schema} = $fixed->{$name};
    }
    else {
      $entry->{install_schema} = $held->{$name} // 'public';
    }
    # The deploy of a connection that names its namespace sees that
    # namespace alone, so it cannot know whether the schema of the extension
    # is there (karr k131): the create makes it.
    my $in = $entry->{declared_schema} // $entry->{install_schema};
    $entry->{create_schema} = 1 if defined $namespace && defined $in && $in ne 'public';
  }
  return $model;
}


sub _mark_namespace {
  my ($self, $model) = @_;
  my $namespace = DBIO::PostgreSQL::DDL::_connection_namespace($self->schema);
  $model->{schemas}{$namespace}{create_if_missing} = 1
    if defined $namespace && $model->{schemas} && $model->{schemas}{$namespace};
  return $model;
}


sub _schema_filter {
  my ($self) = @_;
  my $namespace = DBIO::PostgreSQL::DDL::_connection_namespace($self->schema);
  return [ $namespace ] if defined $namespace;
  my @schemas = DBIO::PostgreSQL::DDL::_schema_decl($self->schema, 'pg_schemas');
  return @schemas ? \@schemas : undef;
}


sub diff {
  my ($self, $opts) = @_;
  $self->_extension_control_schemas;    # a refusal, before a temporary database is made
  # The option stands in new, ahead of the first operations call; a value the
  # caller gave stays. A non-hash $opts goes to the core, which refuses it.
  $opts = { foreign_keys_not_valid => 1, %{ $opts // {} } }
    if $self->foreign_keys_not_valid && (!defined $opts || ref $opts eq 'HASH');
  my $diff = $self->SUPER::diff($opts);
  $diff->operations;
  return $diff unless $self->_schema_filter;
  return $diff if $self->manage_extensions_when_restricted;
  return $self->_diff_class->new(
    source     => $diff->source,
    target     => $diff->target,
    kept_foreign_keys => $diff->{kept_foreign_keys},
    operations => [
      grep { !($_->isa('DBIO::PostgreSQL::Diff::Extension') && $_->action eq 'drop') }
      @{ $diff->operations }
    ],
  );
}


sub _check_before_apply {
  my ($self, $diff) = @_;
  $self->_refuse_unfillable($diff, $self->_dbh);
  return $self->SUPER::_check_before_apply($diff);
}


sub _refuse_unfillable {
  my ($self, $diff, $dbh) = @_;

  for my $op (@{ $diff->operations }) {
    next unless $op->isa('DBIO::PostgreSQL::Diff::Column');
    my $new = $op->new_info or next;
    next unless $new->{not_null};

    my $adds = $op->action eq 'add'
      && !(defined $new->{default_value} && length $new->{default_value})
      && !DBIO::PostgreSQL::Introspect->identity_kind($new->{identity})
      && !DBIO::PostgreSQL::Introspect->generated_kind($new->{generated});
    my $sets = $op->action eq 'alter' && $op->old_info && !$op->old_info->{not_null};
    next unless $adds || $sets;

    my @names = DBIO::PostgreSQL::Introspect->key_names($op->table_key, table_name => $op);
    my $table = DBIO::PostgreSQL::Util::quote_qualified(@names);
    my $label = join '.', @names;
    my $column = $op->column_name;

    if ($adds) {
      next unless $dbh->selectrow_array("SELECT 1 FROM $table LIMIT 1");
      DBIO::Exception->throw(sprintf
        'PostgreSQL refuses to add the column %s.%s: it is NOT NULL without a '
        . 'default, and table %s holds rows that would have no value for it',
        $label, $column, $label);
    }
    next unless $dbh->selectrow_array(sprintf
      'SELECT 1 FROM %s WHERE %s IS NULL LIMIT 1',
      $table, DBIO::PostgreSQL::Util::quote_ident($column));
    DBIO::Exception->throw(sprintf
      'PostgreSQL refuses to make the column %s.%s NOT NULL: table %s holds '
      . 'rows where it is NULL',
      $label, $column, $label);
  }

  return;
}


sub _resolve_extension_list {
  my ($self) = @_;
  return DBIO::PostgreSQL::Extension->resolve_list($self->schema);
}


sub _extension_list {
  my ($self) = @_;
  my $list = $self->_resolve_extension_list or return [];

  $list->set_installed($self->_installed_extensions([ $list->names ]));

  return [ $list->entries ];
}


sub _installed_extensions {
  my ($self, $names) = @_;
  my $rows = $self->_dbh->selectall_arrayref(q{
    SELECT e.extname AS name, e.extversion AS version, n.nspname AS schema
    FROM pg_catalog.pg_extension e
    JOIN pg_catalog.pg_namespace n ON n.oid = e.extnamespace
    WHERE e.extname = ANY($1)
  }, { Slice => {} }, $names);

  my %state = map { $_ => { installed => 0 } } @$names;
  $state{ $_->{name} } = { installed => 1, version => $_->{version}, schema => $_->{schema} }
    for @$rows;
  return \%state;
}


sub _extension_driver_helpers {
  return DBIO::PostgreSQL::Extension->driver_helpers;
}


sub _extension_connection_schema {
  my ($self) = @_;
  return undef unless $self->{schema};
  return DBIO::PostgreSQL::DDL::_connection_namespace($self->schema);
}


sub _extension_restricted {
  my ($self) = @_;
  return 0 unless $self->{schema};
  return defined $self->_schema_filter ? 1 : 0;
}

# --- extension protocol: applying the answers to a model ----------------------

my %_CLAIM = (
  schema => \&_claim_schema,
  table  => \&_claim_table,
  column => \&_claim_column,
  type   => \&_claim_type,
);

sub _unknown_address {
  my ($what, $address) = @_;
  DBIO::Exception->throw(sprintf
    "%s: the address [%s] is of a kind this deploy does not know (schema, table, column, type)",
    $what, join(', ', map { defined $_ ? $_ : 'undef' } @$address));
}


sub _apply_extension_claims {
  my ($self, $model, $addresses) = @_;
  for my $address (@$addresses) {
    my ($kind, @args) = @$address;
    my $claim = $_CLAIM{$kind // ''} or _unknown_address('extension claim', $address);
    $claim->($model, @args);
  }
  return;
}

sub _claim_schema {
  my ($model, $name) = @_;
  delete $model->{schemas}{$name} if $model->{schemas};
  my @tables = grep { ($model->{tables}{$_}{schema_name} // '') eq $name } keys %{ $model->{tables} || {} };
  _claim_table($model, $_) for sort @tables;
  for my $section (qw( types functions sequences )) {
    my $objects = $model->{$section} or next;
    delete $objects->{$_}
      for grep { ($objects->{$_}{schema_name} // '') eq $name } keys %$objects;
  }
  return;
}

# The sequences that belong to the table, or to one of its columns.
sub _owned_sequences {
  my ($model, $table_key, $column) = @_;
  my $table = $model->{tables}{$table_key} or return ();
  my $quoted = DBIO::PostgreSQL::Util::quote_qualified($table->{schema_name}, $table->{table_name});
  my $sequences = $model->{sequences} or return ();
  return grep {
    my $s = $sequences->{$_};
    defined $s->{owned_by_table} && $s->{owned_by_table} eq $quoted
      && (!defined $column || ($s->{owned_by_column} // '') eq $column)
  } keys %$sequences;
}

sub _claim_table {
  my ($model, $key) = @_;
  delete $model->{sequences}{$_} for _owned_sequences($model, $key);
  delete $model->{$_}{$key}
    for grep { $model->{$_} } qw( tables columns indexes triggers policies foreign_keys check_constraints );
  return;
}

sub _claim_column {
  my ($model, $table_key, $column) = @_;
  delete $model->{sequences}{$_} for _owned_sequences($model, $table_key, $column);
  my $columns = $model->{columns}{$table_key} or return;
  @$columns = grep { $_->{column_name} ne $column } @$columns;
  return;
}

sub _claim_type {
  my ($model, $key) = @_;
  delete $model->{types}{$key} if $model->{types};
  return;
}


sub _apply_extension_annotations {
  my ($self, $model, $triples) = @_;
  for my $triple (@$triples) {
    my ($address, $attribute, $value) = @$triple;
    my ($kind, @args) = @$address;
    my $object = $self->_annotated_object($model, $address) or next;
    my $where = join '.', @args;
    DBIO::Exception->throw(sprintf
      "extension annotation: %s '%s' already has the attribute '%s' with another value (an extension adds to an object, it does not rewrite what the introspection read)",
      $kind, $where, $attribute)
      if exists $object->{$attribute} && _differs($object->{$attribute}, $value);
    $object->{$attribute} = ref $value ? Storable::dclone($value) : $value;
  }
  return;
}

sub _differs {
  my ($have, $want) = @_;
  local $Storable::canonical = 1;
  return Storable::nfreeze(\$have) ne Storable::nfreeze(\$want);
}

# The model's entry of the object an address names, or undef when the model
# does not hold it.
sub _annotated_object {
  my ($self, $model, $address) = @_;
  my ($kind, @args) = @$address;
  return $model->{schemas}{ $args[0] } if $kind eq 'schema' && $model->{schemas};
  return $model->{tables}{ $args[0] }  if $kind eq 'table'  && $model->{tables};
  return $model->{types}{ $args[0] }   if $kind eq 'type'   && $model->{types};
  if ($kind eq 'column') {
    my ($found) = grep { $_->{column_name} eq $args[1] } @{ $model->{columns}{ $args[0] } || [] };
    return $found;
  }
  _unknown_address('extension annotation', $address) unless $_CLAIM{$kind // ''};
  return undef;
}


sub _apply_extension_states {
  my ($self, $model, $states) = @_;
  $model->{extension_states} = $states;
  _lock_deep($model->{extension_states});
  return;
}

# Read-only all the way down: hashes (keys and values) and the arrays in them.
sub _lock_deep {
  my ($x) = @_;
  if (ref $x eq 'HASH') {
    _lock_deep($_) for values %$x;
    Hash::Util::lock_hashref($x);
  }
  elsif (ref $x eq 'ARRAY') {
    _lock_deep($_) for @$x;
    Internals::SvREADONLY($_, 1) for @$x;
    Internals::SvREADONLY(@$x, 1);
  }
  return;
}


sub _temp_dsn {
  my ($self, $dsn, $temp_db) = @_;
  my $quoted = DBIO::PostgreSQL::Util::quote_dsn_value($temp_db);

  my ($prefix) = $dsn =~ /\A(dbi:\w*(?:\([^)]*\))?:)/i;
  $prefix //= '';
  my $rest = substr($dsn, length $prefix);

  my $out;
  if ($rest =~ m{\A(\s*postgres(?:ql)?://[^/?#]*)(?:/[^?#]*)?(?:\?([^#]*))?(\#.*)?\z}is) {
    my ($authority, $query, $fragment) = ($1, $2, $3);
    my @query = grep { !/\A(?:dbname|database|db)=/i } split /&/, $query // '';
    (my $path = $temp_db) =~ s/([^A-Za-z0-9._~-])/sprintf '%%%02X', ord $1/ge;
    $out = $prefix . "$authority/$path"
      . (@query ? '?' . join('&', @query) : '') . ($fragment // '');
  }
  else {
    my @params;
    pos($rest) = 0;
    while ($rest =~ /\G[\s;]*([^\s;='\\]+)[\s;]*=[\s;]*((?:'(?:[^'\\]|\\.)*'|(?:\\.|[^\s;'\\])+)?)/gcs) {
      my ($key, $value) = ($1, $2);
      next if grep { lc $key eq $_ } qw(db database dbname);
      push @params, "$key=$value";
    }
    $rest =~ /\G[\s;]*/gc;
    DBIO::Exception->throw('_temp_dsn: the DSN of the live connection is not a list of key=value parameters')
      unless (pos($rest) // 0) == length $rest;
    $out = $prefix . join(';', @params, "dbname=$quoted");
  }

  DBIO::Exception->throw('_temp_dsn: the DSN of the temporary database names no target')
    unless DBIO::PostgreSQL::Util::dsn_names_target($out);
  return $out;
}


sub _refuse_open_transaction {
  my ($self, $dbh, $method) = @_;
  return if $dbh->{AutoCommit};
  DBIO::Exception->throw(sprintf
    '%s: the handle is inside a transaction (AutoCommit is off) and CREATE/DROP DATABASE cannot run in one; '
    . 'no statement was run. DBIO::Deploy::Base::TempDatabase passes a handle with AutoCommit on (_admin_dbh); pass one like it',
    $method);
}

sub _create_temp_db {
  my ($self, $dbh) = @_;
  my $name = $self->temp_db_prefix . $$ . '_' . time() . '_'
    . unpack('H8', Crypt::URandom::urandom(4));
  DBIO::Exception->throw('_create_temp_db: temp_db_prefix leaves the database name longer than 63 bytes')
    if length($name) > 63;
  $self->_refuse_open_transaction($dbh, '_create_temp_db');
  my $version = $dbh->{pg_server_version};
  my $row = $dbh->selectrow_hashref($self->_locale_catalog_sql($version))
    or DBIO::Exception->throw('_create_temp_db: the live database is not in pg_database');
  $dbh->do($self->_create_database_sql($name, $version, $row));
  return $name;
}


sub _locale_catalog_sql {
  my ($self, $version) = @_;
  my $provider = $version >= 150000 ? 'datlocprovider' : 'NULL';
  my $locale   = $version >= 170000 ? 'datlocale'
               : $version >= 150000 ? 'daticulocale' : 'NULL';
  my $rules    = $version >= 160000 ? 'daticurules' : 'NULL';
  return 'SELECT pg_catalog.pg_encoding_to_char(encoding) AS encoding,'
    . " datcollate AS collate, datctype AS ctype,"
    . " $provider AS provider, $locale AS locale, $rules AS icu_rules"
    . ' FROM pg_catalog.pg_database WHERE datname = pg_catalog.current_database()';
}


my %PROVIDER = (c => 'libc', i => 'icu', b => 'builtin');

sub _create_database_sql {
  my ($self, $name, $version, $row) = @_;
  my $q = \&DBIO::PostgreSQL::Util::quote_literal;
  my @sql = (
    'CREATE DATABASE ' . DBIO::PostgreSQL::Util::quote_ident($name),
    'TEMPLATE template0',
    'ENCODING '   . $q->($row->{encoding}),
    'LC_COLLATE ' . $q->($row->{collate}),
    'LC_CTYPE '   . $q->($row->{ctype}),
  );
  if ($version >= 150000) {
    my $provider = $PROVIDER{ $row->{provider} // 'c' }
      or DBIO::Exception->throw(
        "_create_database_sql: unknown locale provider '$row->{provider}' in pg_database");
    push @sql, "LOCALE_PROVIDER $provider";
    push @sql, 'ICU_LOCALE ' . $q->($row->{locale})
      if $provider eq 'icu' && defined $row->{locale};
    push @sql, 'BUILTIN_LOCALE ' . $q->($row->{locale})
      if $provider eq 'builtin' && defined $row->{locale};
    push @sql, 'ICU_RULES ' . $q->($row->{icu_rules})
      if $version >= 160000 && defined $row->{icu_rules} && length $row->{icu_rules};
  }
  return join ' ', @sql;
}


sub _drop_temp_db {
  my ($self, $dbh, $name) = @_;
  $self->_refuse_open_transaction($dbh, '_drop_temp_db');
  $dbh->do(sprintf 'DROP DATABASE IF EXISTS %s', DBIO::PostgreSQL::Util::quote_ident($name));
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::PostgreSQL::Deploy - Deploy and upgrade PostgreSQL schemas via test-deploy-and-compare

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

C<DBIO::PostgreSQL::Deploy> orchestrates the deployment and upgrade of
PostgreSQL schemas using a test-deploy-and-compare strategy. The shared
orchestration (L<install|/install>, L<diff|/diff>,
L<apply|DBIO::Deploy::Base/apply>, L<upgrade|DBIO::Deploy::Base/upgrade>)
and the temporary-database dance are inherited from
L<DBIO::Deploy::Base::TempDatabase>; this class supplies only the genuinely
PostgreSQL-specific seams (the C<CREATE DATABASE> / C<DROP DATABASE>
dialect and the C<schema_filter> passed to the introspector).

For upgrades, the strategy is:

=over 4

=item 1. Introspect the live database via C<pg_catalog>

=item 2. Create a temporary database

=item 3. Deploy the desired schema (from DBIO classes) into the temp database

=item 4. Introspect the temp database via C<pg_catalog>

=item 5. Compute the diff between the two models using L<DBIO::PostgreSQL::Diff>

=item 6. Drop the temp database

=back

The temporary database is an empty database made from C<template0> with the
encoding and the collation of the live database (L</_create_temp_db>). Before
the install DDL runs it is checked to hold nothing but the schema C<public> and
the extension C<plpgsql> (L</_check_database_empty>); anything else stops the
deploy, naming the objects, and the temporary database is dropped. The target
model is therefore only what the schema declares: an extension that lives in the
database and is not declared appears in the diff as undeclared, as before.

This means PostgreSQL is comparing with itself — the diff is always accurate
regardless of how complex the schema features are.

    my $deploy = DBIO::PostgreSQL::Deploy->new(
        schema => MyApp::DB->connect($dsn),
    );

    # Fresh install
    $deploy->install;

    # Upgrade (test-deploy + compare + apply)
    $deploy->upgrade;

    # Or in steps:
    my $diff = $deploy->diff;
    print $diff->summary;
    $deploy->apply($diff) if $diff->has_changes;

    # A diff that drops something, or changes a column's type in a way that
    # may alter stored values, runs only when it is released:
    $deploy->upgrade(allow_destructive => 1);
    $deploy->apply($diff, dry_run => 1);    # executes nothing, returns the diff

The schema need not load the L<DBIO::PostgreSQL> component. The declarations
Deploy reads itself -- C<pg_extensions> for the extension check and
C<pg_schemas> for the introspector's C<schema_filter> -- are answered the way
L<DBIO::PostgreSQL::DDL/install_ddl> answers its own: by the component's
defaults when the schema lacks them. A schema without the component therefore
deploys and diffs exactly like a component-loaded one that declares nothing.

Declaring C<pg_schemas> makes the deploy I<restricted>: it introspects only
those schemas, and because extensions are database-level it creates declared
extensions that are missing but drops none. An unrestricted deploy drops every
extension the schema does not declare. See L</diff>.

A schema connected with the connect key C<schema>
(L<DBIO::PostgreSQL/ONE SCHEMA CLASS IN SEVERAL NAMESPACES>) restricts the
deploy made for it to the namespace of that connection, whatever
C<pg_schemas> the class declares:

    my $schema = MyApp::DB->connect($dsn, $user, $pass, { schema => 'tenant_a' });
    my $deploy = $schema->pg_deploy;

    $deploy->install;    # creates tenant_a when it is not there, installs into it
    $deploy->upgrade;    # compares tenant_a, and nothing beside it

The restriction is this object's. A deploy of the same class over a
connection to C<tenant_b> is restricted to C<tenant_b>, at the same time.

=head1 ATTRIBUTES

=head2 manage_extensions_when_restricted

    my $deploy = DBIO::PostgreSQL::Deploy->new(
        schema                            => $schema,
        manage_extensions_when_restricted => 1,
    );

Boolean, default false. A deploy restricted by L<DBIO::PostgreSQL/pg_schemas>
drops no extension (see L</diff>), since extensions are database-level and
may belong to another application in the same database. Set this to make
L</diff> drop the extensions the schema does not declare even so; declared
ones are created and updated either way. It changes nothing for an
unrestricted deploy, which always drops them. Only C<diff> reads it:
introspection stays restricted to C<pg_schemas>.

=head2 foreign_keys_not_valid

    my $deploy = DBIO::PostgreSQL::Deploy->new(
        schema                 => $schema,
        foreign_keys_not_valid => 1,
    );

Boolean, default false. Without it the diff creates a foreign key with an
ordinary C<ALTER TABLE ... ADD CONSTRAINT ... FOREIGN KEY>, which reads every
row of the table. With it the key is added C<NOT VALID>, which reads none, and
a C<VALIDATE CONSTRAINT> for each follows as a step of its own, behind all of
them (L<DBIO::PostgreSQL::Diff::ForeignKey/with_validation>). A key of a table
the diff creates is added as ever. C<apply> commits the C<ADD CONSTRAINT>
with the rest of the diff and runs each C<VALIDATE CONSTRAINT> after that
COMMIT in a transaction of its own, so the lock of the add is not
held over the reading of the rows. Rows that break a key end C<apply> with
the error, and the key stays C<NOT VALID>. The key is not left NOT VALID
for good: the
diff reads C<convalidated>, so the next C<diff> (and C<upgrade>) finds a key
that is not valid and adds a C<VALIDATE CONSTRAINT> for it; rows that break it
make that upgrade fail until they are cleaned up. Only C<diff> (and so C<upgrade>) reads it.

=head1 METHODS

=head2 install_schema

    $deploy->install_schema('tenant_42');

Creates a single PostgreSQL schema (namespace) using C<CREATE SCHEMA IF NOT
EXISTS>, and nothing in it. The name is taken exactly and written as an
identifier by the server's rule (L<DBIO::PostgreSQL::Util/quote_ident>):
C<Tenant42> creates the schema C<Tenant42>, not C<tenant42>.

To install the schema class into a namespace of its own -- one per tenant --
connect with the connect key C<schema> and call L</install>, which creates the
namespace as well:

    MyApp::DB->connect($dsn, $user, $pass, { schema => 'tenant_42' })
      ->pg_deploy->install;

=head2 install

    $deploy->install;

Overrides L<DBIO::Deploy::Base/install> to check the declared extensions
(L<DBIO::PostgreSQL/pg_extensions>) against the server first, then runs the
inherited install. See L</_check_extensions_available>.

=head2 _deploy_and_introspect_temp

    my $model = $self->_deploy_and_introspect_temp($temp_db);

Overrides L<DBIO::Deploy::Base::TempDatabase/_deploy_and_introspect_temp> to
check the declared extensions before the install DDL runs in the temporary
database. Without this, a declared extension that is missing on the server
fails the temp deploy with a cryptic follow-on error (e.g. C<type "vector"
does not exist> from a later C<CREATE TABLE>) instead of naming the
extension.

=head2 _check_temp_db_empty

    $self->_check_temp_db_empty($temp_db);

Opens a connection of its own to the temporary database (via
L<DBIO::Deploy::Base::TempDatabase/_temp_connect_info>, an error of the connect shown with the password
masked), runs L</_check_database_empty> on it and closes it, before the install
DDL runs. It is called from L</_deploy_and_introspect_temp>, whose error
L<DBIO::Deploy::Base::TempDatabase/_build_target_model> follows by dropping the
temporary database.

=head2 _check_database_empty

    $self->_check_database_empty($dbh);

Introspects the database behind C<$dbh> without a schema filter and dies with
a L<DBIO::Exception> naming every object L</_foreign_objects> finds. Returns
when the database is empty.

=head2 _foreign_objects

    my @found = $self->_foreign_objects($model);

The objects of an introspected model that an empty database made from
C<template0> does not hold: every schema but C<public>, every extension but
C<plpgsql>, and every type, relation, sequence and function. Each is a
description such as C<table public.t>, in that order of kinds and by name.
Empty for the model of an empty database. A pure function of the model.

=head2 _installed_extension_schemas

    my $held = $self->_installed_extension_schemas;   # { citext => 'ext' }

The schemas the live database holds the declared extensions in, for those a
temporary database is to put in the same place: installed, in a
schema other than C<public>, and neither given a schema by
L<DBIO::PostgreSQL/pg_extensions> nor fixed by the control file (those two
decide, as ever). An extension in the namespace of a connection that names
one is left out as well -- the install script refuses an extension there --
and so is one that is not installed. C<{}> when nothing is declared, and then
nothing is read.

=head2 _execute_ddl

    $deploy->_execute_ddl($dbh, $sql);

Core's, with one addition for the temporary database. The install
script does not write L<DBIO::PostgreSQL/pg_search_path>; a connection of the
schema has it as its C<search_path> instead. The handle of the temporary
database is a plain DBI connection that no storage sets up, so before the
script runs on it the declared path is set on it -- by the rule of
L<DBIO::PostgreSQL::Storage/_declared_search_path> -- and an object without a
C<pg_schema> lands in the schema it lands in on the live database. Otherwise
the diff would compare a table in the first schema of the path (live) with one
in C<public> (target) and drop the one to create the other. The handle of the
live connection is not touched, and a schema that declared no path, or whose
connection names its namespace (the script carries that path), sends nothing.
Behind a L<DBIO::Replicated::Storage> the hooks are asked of the driver storage
of its master (C<_driver_storage>), which the replicated storage does not
forward them to.

=head2 _extension_control_schemas

    my $fixed = $self->_extension_control_schemas;   # { age => 'ag_catalog' }

The schemas the control files of the declared extensions fix, read over the
live connection from C<pg_catalog.pg_available_extension_versions> (column
C<schema>) for the version C<CREATE EXTENSION> installs, the default one. Only
an extension that has one is in the answer: C<age> (C<ag_catalog>),
C<postgis_topology> (C<topology>), C<postgis_tiger_geocoder> (C<tiger>),
C<pg_cron> and C<plpgsql> (C<pg_catalog>) -- the server answers, no list is
built in. C<{}> when nothing is declared, and then nothing is read.

A declared schema other than the fixed one dies, naming the extension and both
schemas (L<DBIO::PostgreSQL::DDL/refuse_control_schema>): the server would
refuse the C<CREATE EXTENSION>, and this is said before the first statement
and before the temporary database of a diff is made.

=head2 _install_ddl

The install script (core's C<_install_ddl>), with the schemas the control
files fix (L</_extension_control_schemas>) passed to
L<DBIO::PostgreSQL::DDL/install_ddl> -- for the install and for the temporary
database of a diff alike. For the temporary database only, the schemas the
live database holds the extensions in (L</_installed_extension_schemas>)
go along as C<extension_installed_schemas>; C<install> against the live
database passes none.

=head2 _check_extensions_available

    $deploy->_check_extensions_available;

Checks every extension declared via C<< $schema->pg_extensions >> against
C<pg_catalog.pg_available_extensions> on the live connection and dies with an
actionable L<DBIO::Exception> naming the missing extension(s) and the fix (the
names are written as identifiers by the server's rule, and read from the
catalog by bind), instead of
letting the deploy fail later with a cryptic type error. No-op when nothing
is declared. Availability is cluster-wide, so the live connection answers for
the temporary database too.

=head2 _missing_extension_message

    my $msg = DBIO::PostgreSQL::Deploy->_missing_extension_message('vector');

Pure function: builds the actionable error text for the given missing
extension names. Kept separate from the catalog query so it is testable
offline.

=head2 _new_introspect

    my $intro = $self->_new_introspect($dbh);

Factory for the introspector. No introspector class is made for an extension:
what an extension knows about the model reaches the deploy through the list
(L</EXTENSIONS>).

The base class only passes C<dbh>; here we also forward the C<schema_filter>
derived from the connected schema's C<pg_schemas> so introspection stays
scoped to the schemas this driver manages.

And C<qualified_names>
(L<DBIO::PostgreSQL::Introspect/qualified_names>), the default of the
introspector, set here as well so that a subclass cannot lose it: both
databases of a diff -- the live one, read in the caller's session, and the
temporary one, read in the session that installed it -- are read
under an empty C<search_path>. PostgreSQL writes a
name without its schema whenever the asking session's C<search_path> finds
it, so read each under its own, one trigger, index, function or column type
was two texts, and the diff of a schema just installed dropped and created
them again in every session but the one that installed it. The statements of
a diff are those texts as well, and are run in the caller's session: with the
schema in every name they reach the objects the temporary database meant.

An extension the database has in a schema of its own (C<CREATE EXTENSION
citext WITH SCHEMA ext>) that C<pg_extensions> does not give that schema, and
whose control file fixes none, is installed by the temporary database in that
same schema (L</_installed_extension_schemas>). Otherwise it would
have it in C<public>, a column of one of its types would be C<ext.citext> here
and C<public.citext> there, and the diff would have an C<ALTER COLUMN ... TYPE
public.citext> the database cannot run. A declared schema
(C<< pg_extensions(citext => { schema => 'ext' }) >>) and the one a control file
fixes decide first, as before; a declared schema the database does not have is
moved to (point 8). An extension the database does not have yet is
created in C<public>.

=head2 _build_target_model

    my $model = $self->_build_target_model;

The inherited model of the temporary database
(L<DBIO::Deploy::Base::TempDatabase/_build_target_model>), with the schemas
L<DBIO::PostgreSQL/pg_extensions> declared marked
(L</_mark_extension_schemas>).

=head2 _mark_extension_schemas

    $model = $self->_mark_extension_schemas($model);

Sets C<declared_schema> on the entry of each extension in the C<extensions>
section of C<$model> for which L<DBIO::PostgreSQL/pg_extension_schemas> names
a schema, and returns the model. The temporary database has every extension
in some schema, declared or not, and the model cannot tell which was meant;
L<DBIO::PostgreSQL::Diff::Extension/diff> compares only the declared ones, so
an extension a list names is left where the database has it.

Every declared extension gets C<install_schema> as well: its declared schema,
else the schema the database holds it in when the temporary database put it
there (L</_installed_extension_schemas>), else C<public>. An extension whose control file fixes a schema
(L</_extension_control_schemas>) gets C<control_schema> instead, and its
C<CREATE EXTENSION> is written without the clause: the server installs it
there, creating the schema, and refuses C<WITH SCHEMA> for one that is not
there yet. That is the schema a C<CREATE EXTENSION> of the
diff names (L<DBIO::PostgreSQL::Diff::Extension/as_sql>) -- the session that
applies the diff has some other schema first in its C<search_path> (the
namespace of a connection with the connect key C<schema>, C<ag_catalog> after
the activation of C<age>), and an unqualified C<CREATE EXTENSION> would land
there. C<install_schema> moves nothing: an extension both sides
have, installed in another schema than C<public> and declared without one,
stays where it is.

On a connection that names its namespace (connect key C<schema>) the deploy
sees that namespace alone (L</_schema_filter>), so the diff cannot tell whether
the schema of a declared extension exists, and a diff before the first install
would write a C<CREATE EXTENSION ... WITH SCHEMA> the server refuses. The entry
gets C<create_schema> then -- set when the schema it is created in is not
C<public> -- and its C<create> is written behind a creation of that schema that looks it up in C<pg_namespace> first
(L<DBIO::PostgreSQL::Diff::Extension/as_sql>).

=head2 _mark_namespace

    $model = $self->_mark_namespace($model);

On a connection that names its namespace (connect key C<schema>) sets
C<create_if_missing> on the namespace's entry in the C<schemas> of the target
model, so that the diff creates it with a lookup in C<pg_namespace> instead of
a C<CREATE SCHEMA> that needs C<CREATE> on the database even for a namespace
that is there (L<DBIO::PostgreSQL::Util/create_schema_if_missing>).
Any other connection: the model is returned as it was.

=head2 _schema_filter

    my $filter = $self->_schema_filter;   # ArrayRef or undef

The schemas (namespaces) this deploy is restricted to. For a schema connected
with the connect key C<schema> that is the namespace of its connection and no
other -- read from the storage of this schema object, so two connections of
one class answer each for itself. Otherwise it is the schema's
L<DBIO::PostgreSQL/pg_schemas>, or C<undef> when none are declared. A defined
answer makes the deploy I<restricted> -- it scopes the introspector (see
L</_new_introspect>) and keeps L</diff> from dropping extensions.

=head2 diff

    my $diff = $deploy->diff;
    my $diff = $deploy->diff({ foreign_keys_not_valid => 1 });

Overrides L<DBIO::Deploy::Base/diff>. The optional hash reference holds the
options of the diff class, handed to its C<new> (L<DBIO::PostgreSQL::Diff/diff_options>:
C<foreign_keys_not_valid>); any other key throws. The attribute
L</foreign_keys_not_valid> of the deploy supplies that option when the caller
gives none; a value the caller gives stays. An unrestricted deploy (no
L<DBIO::PostgreSQL/pg_schemas> declared) owns the whole database and returns
the inherited diff unchanged: an extension the schema does not declare is
dropped.

A deploy restricted by C<pg_schemas>, or by the namespace of its connection
(L</_schema_filter>), does not own the database's extensions --
they are database-level, outside every schema it manages, and may belong to
another application in the same database. Its diff still creates declared
extensions that are missing and updates their versions, but it drops B<no>
extension. The C<source> and C<target> models are left as introspected; only
the C<DROP EXTENSION> operations are withheld. With
L</manage_extensions_when_restricted> set, they are not.

Either way the operations are built here, not on first use: a change
L<DBIO::PostgreSQL::Diff> refuses (C<refusing to diff: ...>, see
L<DBIO::PostgreSQL::Diff/WHAT IS REFUSED>) makes C<diff> die, not a later
C<as_sql> or C<apply>.

=head2 _check_before_apply

    $self->_check_before_apply($diff);

The driver's part of L<DBIO::Deploy::Base/apply>, which this class inherits
together with C<upgrade> (the same code, not a copy): once the diff is released
-- refusals, and C<allow_destructive> for a drop or a column type change that
may alter stored values (L<DBIO::PostgreSQL::Diff::Column/lossy>) -- and before
the first statement, it takes one look at the live rows
(L</_refuse_unfillable>): what the server would refuse half way through the
diff for the rows already in a table is refused before the first statement
runs. The statements are rendered and run by the default
C<_execute_diff>; an operation that has no statement refuses there, ahead of the
first one.

=head2 _refuse_unfillable

    $self->_refuse_unfillable($diff, $dbh);

Looks at the rows of the live tables and dies with a L<DBIO::Exception>
naming table and column, ahead of the first statement of C<$diff>:

=over 4

=item * a column the diff adds that is C<NOT NULL> without a default (not an
        identity or a generated column; C<serial> has a default in the model)
        to a table that holds rows: C<PostgreSQL refuses to add the column
        S.T.C: it is NOT NULL without a default, and table S.T holds rows ...>;

=item * a column that becomes C<NOT NULL> in a table that has a C<NULL> in it:
        C<PostgreSQL refuses to make the column S.T.C NOT NULL: table S.T
        holds rows where it is NULL>.

=back

An empty table, and a table with no C<NULL> in the column, pass. A table the
diff itself creates is not looked at: it has no rows.

=head2 _resolve_extension_list

    my $list = $self->_resolve_extension_list;   # DBIO::Extension::List, or undef

The declared list of extensions resolved to classes, without the installed
state and without the database: the classes are loaded, their interface version
and driver checked. C<undef> when the schema declares none. A distribution that
is not installed, a class that does not load, a wrong interface version and a
class of another driver throw here (L<DBIO::Extension::List>).

=head2 _extension_list

    my $entries = $self->_extension_list;

The hook of L<DBIO::Deploy::Base/_extension_list>: the entries of
L</_resolve_extension_list> with the installed state attached, read from
C<pg_catalog.pg_extension> over the live connection (C<installed>, C<version>,
C<schema>; C<installed> is 0 for a declared extension the database does not
have). C<[]> when the schema declares none, and then nothing is read.

=head2 _installed_extensions

    my $state = $self->_installed_extensions(\@names);
    # { postgis => { installed => 1, version => '3.4.2', schema => 'gis' },
    #   age     => { installed => 0 } }

Reads C<pg_catalog.pg_extension> over the live connection for the given names
and answers the installed state of each: C<installed>, and for an installed
one C<version> and C<schema> (the schema the extension depends on). Every name
asked is in the answer.

=head2 _extension_driver_helpers

The helpers every extension gets as C<< $ctx->{driver} >>: C<quote_ident>,
C<quote_qualified>, C<qualified_key> and the address constructors C<schema>,
C<table>, C<column> and C<type> (L</Addresses>).

=head2 _extension_connection_schema

The namespace of the connection (L<DBIO::PostgreSQL/ONE SCHEMA CLASS IN SEVERAL
NAMESPACES>), or C<undef>, for C<< $ctx->{connection_schema} >>.

=head2 _extension_restricted

True when L</_schema_filter> answers, for C<< $ctx->{restricted} >>.

=head2 _apply_extension_claims

    $self->_apply_extension_claims($model, \@addresses);

Removes the claimed objects from the model with their cascade (L</Claims and their cascade>).

=head2 _apply_extension_annotations

    $self->_apply_extension_annotations($model, \@triples);

Sets the attributes on the objects of the model (L</Annotations>).

=head2 _apply_extension_states

    $self->_apply_extension_states($model, \%states);

Puts the states under C<< $model->{extension_states} >>, locked (L</State>).

=head2 _temp_dsn

    my $temp_dsn = $self->_temp_dsn($dsn, $temp_db);

The DSN of the temporary database: the live C<$dsn> with its database name
replaced by C<$temp_db>, or with it added when there is none. The DSN is read
by the rule of L<DBIO::PostgreSQL::Util/dsn_names_target> -- parameters
separated by whitespace or C<;> outside single quotes, a value bare or in
single quotes with a backslash as the escape, C<db> and C<database> for
C<dbname>, a leading C<< dbi:Pg(attributes): >> kept -- so every other
parameter (C<host>, C<port>, C<sslmode>, ...) stays as it was written, in a
DSN with blanks as separators and with a quoted value that holds a C<;>
alike. The name is written by L<DBIO::PostgreSQL::Util/quote_dsn_value>. A
libpq URI (C<postgresql://...>) gets the name as its path, any C<dbname>
parameter of its query removed.

The result is checked by C<dsn_names_target> before it is returned. A DSN
that cannot be read as parameters throws, the message naming no value.

=head2 _create_temp_db

    my $name = $self->_create_temp_db($dbh);

Creates an empty database from C<template0> (C<CREATE DATABASE ... TEMPLATE
template0>), with the encoding and the collation of the live database: its
C<ENCODING>, C<LC_COLLATE> and C<LC_CTYPE> and, where the server has them,
C<LOCALE_PROVIDER> with C<ICU_LOCALE> or C<BUILTIN_LOCALE> and C<ICU_RULES>,
all read from C<pg_database> (L</_locale_catalog_sql>,
L</_create_database_sql>). C<template0> cannot be connected to and is never
changed, so the temporary database holds nothing but what the install DDL puts
there, and the target model is only what the schema declares
(L</_check_temp_db_empty>).

PostgreSQL C<CREATE DATABASE> cannot run inside a transaction block, so the
dbh must be in autocommit mode (core hands out such a handle). A handle with
C<AutoCommit> off dies before any statement runs; its transaction is neither
committed nor changed. Returns the new database name
(C<< temp_db_prefix . $$ . '_' . time() . '_' . 8 hex digits >>). The last part is
random (L<Crypt::URandom>), so the name cannot be known ahead; a prefix that
leaves the name longer than 63 bytes is refused.

=head2 _locale_catalog_sql

    my $sql = $self->_locale_catalog_sql($server_version);

The query for the row L</_create_database_sql> takes: the encoding, collation
and locale of C<current_database()> in C<pg_database>. It names only the
columns the server has (C<datlocprovider> from 15, C<daticulocale> from 15 and
C<datlocale> from 17, C<daticurules> from 16); the others are C<NULL>.
C<$server_version> is C<< $dbh->{pg_server_version} >>.

=head2 _create_database_sql

    my $sql = $self->_create_database_sql($name, $server_version, $row);

The C<CREATE DATABASE> statement of the temporary database C<$name>, a pure
function of the server version and the row of L</_locale_catalog_sql> (keys
C<encoding>, C<collate>, C<ctype>, C<provider>, C<locale>, C<icu_rules>). It
is always C<TEMPLATE template0> with C<ENCODING>, C<LC_COLLATE> and
C<LC_CTYPE>. From PostgreSQL 15 it names the C<LOCALE_PROVIDER> too, with
C<ICU_LOCALE> for C<icu> and, for C<builtin> (17), C<BUILTIN_LOCALE>; from 16
C<ICU_RULES> where the database has rules. Every value from the catalog is
written as a literal (L<DBIO::PostgreSQL::Util/quote_literal>).

=head2 _drop_temp_db

    $self->_drop_temp_db($dbh, $name);

Drops the temporary database. The dbh must be in autocommit mode; a handle
inside a transaction dies before any statement runs (symmetric to
L</_create_temp_db>).

=head1 EXTENSIONS

The database extensions a schema has are a declared list the deploy runs (ADR
0066 of DBIO core). This class is the driver's side of it; the protocol itself
-- the phases, the merges and their refusals -- is core's
(L<DBIO::Deploy::Base/diff>, L<DBIO::Extension::Protocol>), and the classes of
the extensions are the family's (L<DBIO::Extension>, L<DBIO::PostgreSQL::Extension>).

=head2 The form of the declaration

The list is L<DBIO::PostgreSQL/pg_extensions> and nothing else; an extension is
not pulled in by loading a component.

  __PACKAGE__->pg_extensions('age', postgis => { schema => 'gis' }, 'citext');
  __PACKAGE__->pg_extensions(vector => { class => 'MyApp::DB::Extension::Vector' });

A name the family has a class for gets it from the fixed table of
L<DBIO::PostgreSQL::Extension> (C<age>, C<postgis>, C<postgis_topology>); the
option C<class> names the class of an extension outside the family and wins; any
other name gets the plain class, which has no rules. The class is loaded and its
interface version and driver checked when the list is resolved
(L</_extension_list>): at L</install>, and at L</diff>. A distribution that is
not installed refuses, naming it.

=head2 Installed state

The installed state of each declared extension is read from
C<pg_catalog.pg_extension> over the live connection and attached to its entry:
C<installed>, C<version>, C<schema>. It is what the rules see in C<< $ctx->{self} >>
and C<< $ctx->{peers} >>. An extension that is installed but not declared is not
in the list; the member filter of L<DBIO::PostgreSQL::Introspect> still keeps
its objects out of the model.

=head2 What a deploy does with an extension

Creating, updating and dropping the extension is the existing diff of
L<DBIO::PostgreSQL::Diff::Extension>; the protocol adds to it, it does not
replace it. A declared extension that is missing is created, a declared one with
another version is updated, one declared with a schema is moved or refused
(L<DBIO::PostgreSQL/pg_extensions>). An installed extension that is not declared
is dropped by an unrestricted deploy and kept by a restricted one
(L</diff>, L</manage_extensions_when_restricted>), whatever rules it has: the
list only holds what is declared, so an undeclared extension's rules do not run.
The deploy is I<restricted> for the protocol (C<< $ctx->{restricted} >>) when
L</_schema_filter> answers, i.e. with C<pg_schemas> or the namespace of the
connection.

=head2 Addresses

An address names an object of the model. The deploy knows four kinds; an
address of another kind is refused, naming it.

  [ schema => $name ]                 a schema (namespace)
  [ table  => $key ]                  a table, view or any relation, by the key of the model
  [ column => $table_key, $column ]   one column of a table
  [ type   => $key ]                  an enum, composite or range type, by the key of the model

A key is where the model files an object, C<schema.name>
(L<DBIO::PostgreSQL::Introspect/qualified_key>); the helpers in
C<< $ctx->{driver} >> build them: C<quote_ident>, C<quote_qualified>,
C<qualified_key($schema, $name)>, and the address constructors C<schema($name)>,
C<table($key)> or C<table($schema, $name)>, C<column($table_key, $column)> or
C<column($schema, $table, $column)>, C<type($key)> or C<type($schema, $name)>.

=head2 Claims and their cascade

An extension claims an address when the object is its own and not the
application's (AGE: the schema of a graph). Claiming removes the object from the
model, on both sides of a diff, so the diff neither creates nor drops it. An
address the model does not hold is passed over: claiming is idempotent.

=over 4

=item * A claimed B<schema> takes the schema, every table of it with what the
table cascades (below), and every type, function and sequence of it.

=item * A claimed B<table> takes the table and its columns, indexes, triggers,
policies, foreign keys, CHECK constraints and the sequences that belong to its
columns (identity columns included).

=item * A claimed B<column> takes the column and the sequences that belong to
it. Indexes and constraints over it are the extension's to claim by their table.

=item * A claimed B<type> takes the type.

=back

What is not followed: a foreign key of another table that points at a claimed
table, a view outside the claimed object that reads it, and a view's
C<depends_on> entry. They stay as the database has them.

=head2 Annotations

An annotation is C<< [ $address, $attribute, $value ] >>: the attribute is set
on the model's entry of the object (the column's hash, the table's, the type's
or the schema's), where the diff's refusals and the rules of the next phase can
read it (C<old_info> and C<new_info> of a verdict carry them). It is set on
both sides of a diff. An object the model does not hold is passed over, since
one side of a diff may not have it yet. An attribute that the model already
carries with another value is refused, naming object and attribute: an
extension adds to an object, it does not rewrite what the introspection read.
Two extensions that give one attribute two values are refused by the protocol.

=head2 State

What an extension's C<inspect> returned is put into the model as
C<< $model->{extension_states}{$name} >>, read-only all the way down (hashes
locked with L<Hash::Util>, arrays and their elements read-only); the section
C<extensions> that the introspection fills is not touched. A deploy never
creates or drops it.

=head2 Verdicts

A change of the type of a column is asked of the extensions before it is
written (L<DBIO::PostgreSQL::Diff::Column/diff>): C<< { using => $expr } >> is
written as the C<USING> of the statement, in place of the cast the diff would
write, and C<< { refuse => [...] } >> refuses the diff with every message.

=head2 Not here

The activation of the extensions per connection (C<LOAD>, the C<search_path>,
L<DBIO::PostgreSQL::Storage/_apply_connection_schema>) and the registration of
the storage layers the classes name (L<DBIO::PostgreSQL/connection>) are the
connect path's and the storage's, not the deploy's. The install script of a
connection that names its namespace sets the C<search_path> of
L<DBIO::PostgreSQL::Util/connection_search_path> at its head, without the activation
entries: an install needs none of them, and the extension's C<activation> is
not asked outside a connection.

=head1 SEE ALSO

=pod

=over 4

=item * L<DBIO::PostgreSQL> - schema component with C<pg_deploy> factory method

=item * L<DBIO::PostgreSQL::DDL> - generates the DDL used by C<install> and C<diff>

=item * L<DBIO::PostgreSQL::Introspect> - reads the live and temp database state

=item * L<DBIO::PostgreSQL::Diff> - compares the two introspected models

=item * L<DBIO::Deploy::Base::TempDatabase> - inherited orchestration

=back

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
