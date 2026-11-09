package DBIO::Informix::Introspect;
# ABSTRACT: Introspect an Informix database via its system catalog

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::Introspect::Base';

use DBIO::Informix::Introspect::Tables;
use DBIO::Informix::Introspect::Columns;
use DBIO::Informix::Introspect::Indexes;
use DBIO::Informix::Introspect::ForeignKeys;
use DBIO::Informix::Introspect::UniqueConstraints;


sub new { my ($class, %args) = @_; bless \%args, $class }

sub dbh    { $_[0]->{dbh} }
sub schema {
  my $self = shift;
  $self->{schema} //= do {
    my ($db) = $self->dbh->selectrow_array(
      q{SELECT DBINFO('dbname') FROM systables WHERE tabid = 1}
    );
    $db =~ s/\s+\z// if defined $db;    # dbinfo pads with blanks
    $db;
  };
}


sub _build_model {
  my ($self) = @_;
  my $dbh    = $self->dbh;
  my $schema = $self->schema;

  my $tables  = DBIO::Informix::Introspect::Tables->fetch($dbh, $schema);
  my $columns = DBIO::Informix::Introspect::Columns->fetch($dbh, $schema, $tables);
  my $indexes = DBIO::Informix::Introspect::Indexes->fetch($dbh, $schema, $tables);
  my $fks     = DBIO::Informix::Introspect::ForeignKeys->fetch($dbh, $schema, $tables);
  my $uniques = DBIO::Informix::Introspect::UniqueConstraints->fetch($dbh, $schema, $tables);

  return {
    tables       => $tables,
    columns      => $columns,
    indexes      => $indexes,
    foreign_keys => $fks,
    unique_constraints => $uniques,
  };
}



sub table_columns_info {
  my ($self, $key) = @_;
  my %info;
  for my $col (@{ $self->model->{columns}{$key} || [] }) {
    my %col_info = (
      data_type         => $col->{data_type},
      is_nullable       => $col->{not_null} ? 0 : 1,
      is_auto_increment => $col->{is_auto_increment} ? 1 : 0,
    );
    $col_info{size}          = $col->{size}          if defined $col->{size};
    $col_info{default_value} = $col->{default_value} if defined $col->{default_value};
    $info{ $col->{column_name} } = \%col_info;
  }
  return \%info;
}


sub table_uniq_info {
  my ($self, $key) = @_;

  my $pk_sig  = join "\0", sort @{ $self->table_pk_info($key) };
  my $indexes = $self->model->{indexes}{$key} || {};

  my @uniq;
  for my $name (sort keys %$indexes) {
    my $idx = $indexes->{$name};
    next unless $idx->{unique};
    next unless @{ $idx->{columns} || [] };
    next if length $pk_sig && (join "\0", sort @{ $idx->{columns} }) eq $pk_sig;
    push @uniq, [ $name => $idx->{columns} ];
  }
  for my $uc (@{ $self->model->{unique_constraints}{$key} || [] }) {
    push @uniq, [ $uc->{constraint_name} => $uc->{columns} ];
  }
  return \@uniq;
}


sub table_fk_info {
  my ($self, $key) = @_;
  my @fks;
  for my $fk (@{ $self->model->{foreign_keys}{$key} || [] }) {
    push @fks, {
      constraint_name  => $fk->{fk_name},
      local_columns    => $fk->{from_columns},
      remote_table     => $fk->{to_table},
      remote_schema    => undef,
      remote_columns   => $fk->{to_columns},
      attrs            => {
        on_update => $fk->{upd_rule},
        on_delete => $fk->{del_rule},
      },
    };
  }
  return \@fks;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Informix::Introspect - Introspect an Informix database via its system catalog

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

C<DBIO::Informix::Introspect> reads the live state of an Informix database via
its system catalog (C<systables>, C<syscolumns>, C<sysindexes>,
C<sysconstraints>, C<sysreferences>, C<sysdefaults>, C<sysviews>) and returns
a unified model hashref. It is the source side of the test-deploy-and-compare
strategy used by L<DBIO::Informix::Deploy>.

    my $intro = DBIO::Informix::Introspect->new(dbh => $dbh);
    my $model = $intro->model;
    # $model->{tables}, $model->{columns}, $model->{indexes}, $model->{foreign_keys}

Model shape mirrors L<DBIO::SQLite::Introspect>:

    {
        tables       => { $name => { ... } },
        columns      => { $table => [ { ... }, ... ] },
        indexes      => { $table => { $name => { ... } } },
        foreign_keys => { $table => [ { ... }, ... ] },
        unique_constraints => { $table => [ { constraint_name => 'u', columns => [ ... ] }, ... ] },
    }

A view is a table of C<kind> C<view> and carries its C<definition> (the
C<CREATE VIEW> text the server keeps).

=head1 ATTRIBUTES

=head2 dbh

A connected C<DBI> handle for Informix. Required.

The readers (Tables, Columns, Indexes, ForeignKeys) are measured against
Informix 15.0.1; C<t/60-introspect-live.t> runs them on a server.

=head2 schema

The name of the database whose catalog is read (the C<"database":informix>
qualifier of the C<sys*> tables). Defaults to the database the handle is
connected to.

=head1 METHODS

=head2 table_columns_info

    my \%info = %{ $intro->table_columns_info($key) };

Hashref of column metadata keyed by column name. Unlike the
L<DBIO::Introspect::Base> default, the C<default_value> and C<size>
keys are omitted entirely when their value is undef -- DBIO::Generate
probes for key presence with C<exists()>, and a literal undef would
trigger spurious matches.

=head2 table_uniq_info

    my \@constraints = @{ $intro->table_uniq_info($key) };

List of C<[ $constraint_name, \@col_names ]> pairs. The unique index backing
the primary key is excluded by matching the PK's column signature -- the
canonical C<origin =E<gt> 'pk'> marker is not available on Informix
introspected indexes.

=head2 table_fk_info

    my \@fks = @{ $intro->table_fk_info($key) };

Each FK is a hashref as described in L<DBIO::Introspect::Base>.
Informix's raw C<upd_rule> / C<del_rule> are mapped to the canonical
C<on_update> / C<on_delete> attrs, and the raw constraint name is
preserved as C<constraint_name> for downstream callers.

=head1 NORMALIZED CONTRACT

C<DBIO::Introspect::Base> ships default implementations of C<table_keys>,
C<table_columns>, C<table_pk_info> and C<table_is_view> that read the
canonical model shape. Informix's model is canonical (bare table names,
declaration-ordered columns, C<kind> on tables, C<is_pk>/C<pk_position>
on columns) so all four are inherited unchanged.

Three methods are overridden because Informix's model or Generate's
expectations diverge from the canonical defaults:

=over 4

=item * L</table_columns_info> -- the canonical default always emits
C<default_value>, even when undef. DBIO::Generate styles test key
presence with C<exists()>, so a literal undef would emit a spurious key.
We omit C<default_value> and C<size> keys when their value is undef.

=item * L</table_uniq_info> -- the canonical default excludes an index
from unique constraints when C<< origin => 'pk' >> or C<uc($name) eq
'PRIMARY'>. The Informix introspector does not record origin, so the
C<PRIMARY> name check alone is insufficient; the PK signature must be
matched by column list.

=item * L</table_fk_info> -- Informix's foreign-key rows carry
C<upd_rule> / C<del_rule>; the canonical default expects C<on_update> /
C<on_delete>. We map between them and attach C<constraint_name> for
downstream callers that need the raw IBM name.

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
