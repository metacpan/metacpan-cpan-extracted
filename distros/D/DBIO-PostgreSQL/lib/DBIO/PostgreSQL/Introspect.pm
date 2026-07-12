package DBIO::PostgreSQL::Introspect;
# ABSTRACT: Introspect a PostgreSQL database via pg_catalog

use strict;
use warnings;

use base 'DBIO::Introspect::Base';


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
use DBIO::PostgreSQL::Introspect::ForeignKeys;
use DBIO::PostgreSQL::Introspect::CheckConstraints;
use DBIO::PostgreSQL::Introspect::Normalize;

sub schema_filter { $_[0]->{schema_filter} }
sub preserve_case { $_[0]->{preserve_case} // 0 }


sub _build_model {
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


sub system_schema_filter {
  my ($class, $alias) = @_;
  $alias //= 'n';
  return "AND $alias.nspname !~ '^pg_'\n      AND $alias.nspname != 'information_schema'";
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
      is_nullable => $column->{not_null} ? 0 : 1,
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
  $def =~ s/\s+\z//;
  $def =~ s/\s*;\s*\z//;
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

    my $simple_unique = $index->{is_unique}
      && !$index->{predicate}
      && !$index->{expressions}
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

    $pg_indexes{$name} = \%def if %def;
  }
  for my $name (sort keys %pg_indexes) {
    push @stmts, [pg_index => $name, $pg_indexes{$name}];
  }

  my $triggers = $self->model->{triggers}{$table_key} || {};
  for my $name (sort keys %$triggers) {
    my $trigger = $triggers->{$name};
    my ($execute) = ($trigger->{definition} || '') =~ /\bEXECUTE\s+FUNCTION\s+(.+?)\s*;?\s*\z/i;
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

version 0.900001

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
functions, RLS policies, and sequences. The same model shape is consumed by
L<DBIO::PostgreSQL::Diff> and by the test-deploy workflow in
L<DBIO::PostgreSQL::Deploy>. On top of it, this class implements the
normalized generation contract from L<DBIO::Introspect::Base> so it can act
as a L<DBIO::Generate> source.

=head1 ATTRIBUTES

=head2 schema_filter

Optional ArrayRef of PostgreSQL schema names to restrict introspection to.
When C<undef>, all non-system schemas are introspected.

=head1 METHODS

=head2 table_keys

Returns sorted ArrayRef of schema-qualified table keys (C<schema.name>).

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

These methods implement the generation contract defined in
L<DBIO::Introspect::Base>. They build on the native model.

=head2 identity_kind

    my $kind = DBIO::PostgreSQL::Introspect->identity_kind($id);

Maps the C<attidentity> opcode from C<pg_catalog.pg_attribute> to the SQL
keyword that follows C<GENERATED> in C<CREATE TABLE>: C<'a'> becomes
C<'ALWAYS'>, C<'d'> becomes C<'BY DEFAULT'>, anything else (including
C<undef> and C<''>) returns C<undef>. The same map is needed by every site
that emits identity syntax (Diff::Column, Diff::Table, DDL).

=head2 qualified_key

    my $key = DBIO::PostgreSQL::Introspect->qualified_key($schema, $name);
    my $key = DBIO::PostgreSQL::Introspect->qualified_key($row);

Builds the canonical C<"schema.name"> key used to index introspected
models. Accepts either two positional args (C<$schema>, C<$name>) or a
single hashref that contains both C<schema_name> and one of C<table_name>,
C<type_name>, C<function_name>, C<sequence_name>, C<index_name>, or
C<policy_name>. Centralising the construction here keeps every section
key in lockstep — if the separator ever changes, only this helper moves.

=head2 system_schema_filter

    my $sql = DBIO::PostgreSQL::Introspect->system_schema_filter($alias);

Returns a two-line SQL fragment for the C<pg_catalog> namespace filter
that excludes the PostgreSQL reserved namespaces (C<pg_*> and
C<information_schema>). The optional C<$alias> is the alias used in the
query for the C<pg_namespace> row (defaults to C<n>). Every introspect
helper concatenates this fragment into its C<WHERE> clause so the set
of excluded namespaces is centralised.

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
