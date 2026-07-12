package DBIO::SQLite;
# ABSTRACT: SQLite-specific schema management for DBIO
our $VERSION = '0.900001';
use strict;
use warnings;

use base 'DBIO::Base';


sub connection {
  my ($self, @info) = @_;
  $self->storage_type('+DBIO::SQLite::Storage');
  return $self->next::method(@info);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::SQLite - SQLite-specific schema management for DBIO

=head1 VERSION

version 0.900001

=head1 SYNOPSIS

=head2 Schema class

  package MyApp::Schema;
  use DBIO Schema => -sqlite;

The C<-sqlite> shortcut pins C<+DBIO::SQLite::Storage> as the storage type.
It is equivalent to the explicit component form:

  package MyApp::Schema;
  use DBIO 'Schema';
  __PACKAGE__->load_components('SQLite');

=head2 Result classes

  package MyApp::Schema::Result::Artist;
  use DBIO;

  __PACKAGE__->table('artist');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer', is_auto_increment => 1 },
    name => { data_type => 'varchar', size => 100 },
  );
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->has_many(cds => 'MyApp::Schema::Result::CD', 'artist_id');

  package MyApp::Schema::Result::CD;
  use DBIO;

  __PACKAGE__->table('cd');
  __PACKAGE__->add_columns(
    id        => { data_type => 'integer', is_auto_increment => 1 },
    artist_id => { data_type => 'integer' },
    title     => { data_type => 'varchar', size => 200 },
  );
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->belongs_to(artist => 'MyApp::Schema::Result::Artist', 'artist_id');

=head2 Connecting

  my $schema = MyApp::Schema->connect('dbi:SQLite:db/app.db');
  $schema->deploy;

  my $artist = $schema->resultset('Artist')->create({ name => 'Sonic Youth' });
  my @cds    = $artist->cds->all;

The classic C<use base> form is still supported:

  package MyApp::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('SQLite');

=head1 DESCRIPTION

L<DBIO::SQLite> is the SQLite driver component for DBIO.

When this component is loaded into a schema class, C<connection()> sets
L<DBIO::Schema/storage_type> to C<+DBIO::SQLite::Storage>, which enables
SQLite-specific storage behavior automatically.

=head1 METHODS

=head2 connection

Overrides L<DBIO/connection> to force C<+DBIO::SQLite::Storage> as
C<storage_type>.

=head1 MIGRATION NOTES

SQLite storage and SQLMaker classes were split out of the historical
DBIx::Class monolithic distribution:

=over 4

=item *

Old: C<DBIx::Class::Storage::DBI::SQLite>

=item *

New: C<DBIO::SQLite::Storage>

=item *

Old: C<DBIx::Class::SQLMaker::SQLite>

=item *

New: C<DBIO::SQLite::SQLMaker>

=back

If C<DBIO-SQLite> is installed, core L<DBIO::Storage::DBI> can autodetect
SQLite DSNs and load the new storage class via the driver registry.

=head1 TESTING

SQLite tests in this distribution use in-memory databases and do not require
database credentials.

Offline SQLMaker tests can use L<DBIO::SQLite::Test> or L<DBIO::Test> with:

  storage_type => 'DBIO::SQLite::Storage'

Shared tests can also exercise the replicated path with:

  replicated   => 1,
  storage_type => 'DBIO::SQLite::Storage'

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
