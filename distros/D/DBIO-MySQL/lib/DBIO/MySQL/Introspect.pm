package DBIO::MySQL::Introspect;
# ABSTRACT: Introspect a MySQL/MariaDB database via information_schema

use strict;
use warnings;

use base 'DBIO::Introspect::Base';

use DBIO::MySQL::Introspect::Tables;
use DBIO::MySQL::Introspect::Columns;
use DBIO::MySQL::Introspect::Indexes;
use DBIO::MySQL::Introspect::ForeignKeys;


sub _build_model {
  my ($self) = @_;
  my $dbh    = $self->dbh;

  my $tables = DBIO::MySQL::Introspect::Tables->fetch($dbh);
  return {
    tables       => $tables,
    columns      => DBIO::MySQL::Introspect::Columns->fetch($dbh, $tables),
    indexes      => DBIO::MySQL::Introspect::Indexes->fetch($dbh, $tables),
    foreign_keys => DBIO::MySQL::Introspect::ForeignKeys->fetch($dbh, $tables),
  };
}

sub view_definition {
  my ($self, $key) = @_;
  my $model = $self->model;
  my $tbl = $model->{tables}{$key} // {};
  return undef unless ($tbl->{kind} // '') eq 'view';

  my ($def) = $self->dbh->selectrow_array(
    q{SELECT view_definition FROM information_schema.views
      WHERE table_schema = DATABASE() AND table_name = ?},
    undef, $key,
  );
  return $def;
}

sub result_class_extra_statements {
  my ($self, $key) = @_;
  my $model = $self->model;
  my $tbl = $model->{tables}{$key} // {};

  # source_info is a plain setter -- emit ONE statement, a second call
  # would replace the first
  my %info;
  $info{mysql_engine}    = $tbl->{engine}          if $tbl->{engine};
  $info{mysql_collation} = $tbl->{table_collation} if $tbl->{table_collation};

  return %info ? ([ source_info => \%info ]) : ();
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::MySQL::Introspect - Introspect a MySQL/MariaDB database via information_schema

=head1 VERSION

version 0.900001

=head1 DESCRIPTION

C<DBIO::MySQL::Introspect> reads the live state of a MySQL or MariaDB
database via C<information_schema> and returns a unified model
hashref. It is the source side of the test-deploy-and-compare strategy
used by L<DBIO::MySQL::Deploy>.

    my $intro = DBIO::MySQL::Introspect->new(dbh => $dbh);
    my $model = $intro->model;
    # $model->{tables}, $model->{columns}, $model->{indexes}, $model->{foreign_keys}

The model shape mirrors L<DBIO::PostgreSQL::Introspect> and
L<DBIO::SQLite::Introspect> so the same diff/deploy patterns apply.

The introspection is scoped to the current database (the C<dbname>
component of the DSN) via C<DATABASE()> -- to introspect a different
schema, connect with that database in the DSN.

Each model section is fetched by a per-section reader under the
C<Introspect/> subdirectory (L<DBIO::MySQL::Introspect::Tables>,
L<DBIO::MySQL::Introspect::Columns>, L<DBIO::MySQL::Introspect::Indexes>,
L<DBIO::MySQL::Introspect::ForeignKeys>), matching the family layout
mandated by core ADR 0018. The shared C<$tables> filter and C<column_type>
size parser live in L<DBIO::MySQL::Introspect::Util>.

Most of the generation contract (C<table_keys>, C<table_columns>,
C<table_columns_info>, C<table_pk_info>, C<table_uniq_info>,
C<table_fk_info>, C<table_is_view>) is provided by
L<DBIO::Introspect::Base>; this subclass only overrides the bits
that are genuinely MySQL-specific -- the model assembly that delegates to
the per-section readers, the view-definition source, and the result-class
C<source_info> emission.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
