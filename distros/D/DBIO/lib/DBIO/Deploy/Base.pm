package DBIO::Deploy::Base;
# ABSTRACT: Base class for DBIO driver deploy orchestrators

use strict;
use warnings;

# Loaded without importing: importing _split_statements would leak it into
# this package's method-resolution namespace (t/55namespaces_cleaned.t).
use DBIO::SQL::Util ();


sub new {
  my ($class, %args) = @_;
  return bless { %args }, $class;
}


sub schema { $_[0]->{schema} }

sub _dbh { $_[0]->schema->storage->dbh }

# --- abstract hooks: the driver's helper classes -----------------------------


sub _ddl_class { die ref(shift) . '::_ddl_class not implemented' }


sub _introspect_class { die ref(shift) . '::_introspect_class not implemented' }


sub _diff_class { die ref(shift) . '::_diff_class not implemented' }

# --- overridable factories / glue --------------------------------------------


sub _new_introspect {
  my ($self, $dbh) = @_;
  return $self->_introspect_class->new(dbh => $dbh);
}


sub _introspect_current {
  my ($self) = @_;
  return $self->_new_introspect($self->_dbh)->model;
}


sub _install_ddl {
  my ($self) = @_;
  return $self->_ddl_class->install_ddl($self->schema);
}


sub _execute_ddl {
  my ($self, $dbh, $sql) = @_;
  for my $stmt (DBIO::SQL::Util::_split_statements($sql)) {
    next if $stmt =~ /^\s*--/;
    $dbh->do($stmt);
  }
  return 1;
}


sub _build_target_model {
  die ref(shift) . '::_build_target_model not implemented';
}

# --- public orchestration ----------------------------------------------------


sub install {
  my ($self) = @_;
  $self->_execute_ddl($self->_dbh, $self->_install_ddl);
  return 1;
}


sub diff {
  my ($self) = @_;
  my $source_model = $self->_introspect_current;
  my $target_model = $self->_build_target_model;
  return $self->_diff_class->new(
    source => $source_model,
    target => $target_model,
  );
}


sub apply {
  my ($self, $diff) = @_;
  return unless $diff->has_changes;
  $self->_execute_ddl($self->_dbh, $diff->as_sql);
  return 1;
}


sub upgrade {
  my ($self) = @_;
  my $diff = $self->diff;
  return unless $diff->has_changes;
  $self->apply($diff);
  return $diff;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Deploy::Base - Base class for DBIO driver deploy orchestrators

=head1 VERSION

version 0.900000

=head1 DESCRIPTION

Base class for the per-driver C<Deploy> orchestrators
(L<DBIO::PostgreSQL::Deploy>, L<DBIO::MySQL::Deploy>, L<DBIO::DuckDB::Deploy>,
L<DBIO::SQLite::Deploy>). Those classes implement the same
test-deploy-and-compare strategy and their C<install>/C<apply>/C<upgrade>
methods were byte-near-identical; only the way C<diff> obtains the I<target>
model (deploy the desired schema into a throwaway database and introspect it)
is genuinely engine-specific.

This base hosts the shared orchestration:

=over 4

=item * L</install> -- generate install DDL and run it against the live db.

=item * L</apply> -- run a diff's SQL against the live db.

=item * L</upgrade> -- L</diff> then L</apply>.

=item * L</diff> -- introspect the live db (source), build the target model,
and hand both to the driver's diff class.

=back

against a handful of hooks. A subclass must provide the three class-name hooks
(L</_ddl_class>, L</_introspect_class>, L</_diff_class>) and L</_build_target_model>
-- the "make a throwaway, deploy the desired schema, introspect it" step that
is the real engine seam. Drivers that use a temporary I<database> (PostgreSQL,
MySQL) get a ready-made L</_build_target_model> by subclassing
L<DBIO::Deploy::Base::TempDatabase> instead; in-memory drivers (DuckDB, SQLite)
override L</_build_target_model> directly with a C<:memory:> connection.

=head1 ATTRIBUTES

=head2 schema

A connected L<DBIO::Schema> instance using the driver's component. Required.

=head1 METHODS

=head2 new

    my $deploy = $class->new(schema => $connected_schema, %extra);

Blesses the argument hash. C<schema> is required.

=head2 _ddl_class

Class name whose C<install_ddl($schema)> returns the install DDL. Abstract.

=head2 _introspect_class

Class name whose C<< new(dbh => $dbh)->model >> returns an introspected model.
Abstract.

=head2 _diff_class

Class name whose C<< new(source => $m, target => $m) >> returns a diff object
(responding to C<has_changes> and C<as_sql>). Abstract.

=head2 _new_introspect

    my $intro = $self->_new_introspect($dbh);

Factory for an introspector over C<$dbh>. Default: C<< _introspect_class->new(dbh => $dbh) >>.
Override to pass extra construction args (e.g. PostgreSQL's C<schema_filter>).

=head2 _introspect_current

The introspected model of the live (source) database. Default:
C<< $self->_new_introspect($self->_dbh)->model >>.

=head2 _install_ddl

The install DDL string for the connected schema. Default:
C<< _ddl_class->install_ddl($self->schema) >>.

=head2 _execute_ddl

    $self->_execute_ddl($dbh, $sql);

Splits C<$sql> into statements (L<DBIO::SQL::Util/_split_statements>) and runs
each via C<< $dbh->do >>, skipping comment-only statements.

=head2 _build_target_model

The desired-state model: deploy the install DDL into a throwaway database and
introspect it. Abstract here -- provided by L<DBIO::Deploy::Base::TempDatabase>
for temp-database drivers, or overridden directly by in-memory drivers.

=head2 install

    $deploy->install;

Generates the install DDL and executes it against the connected database.
Suitable for a fresh install on an empty database. Returns true.

=head2 diff

    my $diff = $deploy->diff;

Introspects the live database (source), builds the target model via
L</_build_target_model>, and returns C<< _diff_class->new(source => ..., target => ...) >>.

=head2 apply

    $deploy->apply($diff);

Executes each statement of C<< $diff->as_sql >> against the connected
database. No-op (returns false) when C<< $diff->has_changes >> is false.

=head2 upgrade

    my $diff = $deploy->upgrade;

Convenience: L</diff> then L</apply>. Returns the diff object if changes were
applied, or C<undef> if the database was already up to date.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
