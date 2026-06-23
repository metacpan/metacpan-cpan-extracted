package DBIO::MySQL;
# ABSTRACT: MySQL-specific schema management for DBIO
our $VERSION = '0.900000';

use strict;
use warnings;

use base 'DBIO::Base';


sub connection {
  my ($self, @info) = @_;
  $self->storage_type('+DBIO::MySQL::Storage');
  return $self->next::method(@info);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::MySQL - MySQL-specific schema management for DBIO

=head1 VERSION

version 0.900000

=head1 SYNOPSIS

=head2 Schema class

  package MyApp::Schema;
  use DBIO Schema => -mysql;

The C<-mysql> shortcut pins C<+DBIO::MySQL::Storage> as the C<storage_type>
and is equivalent to the classic component form below.

  package MyApp::Schema;
  use DBIO 'Schema';
  __PACKAGE__->load_components('MySQL');

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

  my $schema = MyApp::Schema->connect($dsn, $user, $pass);
  $schema->deploy;

  my $artist = $schema->resultset('Artist')->create({ name => 'Sonic Youth' });
  my @cds    = $artist->cds->all;

For MariaDB use C<MySQL::MariaDB> instead:

  __PACKAGE__->load_components('MySQL::MariaDB');

The classic C<use base> form is still supported:

  package MyApp::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('MySQL');

=head1 DESCRIPTION

L<DBIO::MySQL> is the MySQL driver component for DBIO.

When this component is loaded into a schema class, C<connection()> sets
L<DBIO::Schema/storage_type> to C<+DBIO::MySQL::Storage>, which enables
MySQL-specific storage behavior automatically.

For MariaDB-specific behavior, see L<DBIO::MySQL::MariaDB> and
L<DBIO::MySQL::Storage::MariaDB>.

=head1 METHODS

=head2 connection

Overrides L<DBIO/connection> to force C<+DBIO::MySQL::Storage> as
C<storage_type>.

=head1 MIGRATION NOTES

MySQL storage and SQLMaker classes were split out of the historical
DBIx::Class monolithic distribution:

=over 4

=item *

Old: C<DBIx::Class::Storage::DBI::mysql>

=item *

New: C<DBIO::MySQL::Storage>

=item *

Old: C<DBIx::Class::Storage::DBI::MariaDB>

=item *

New: C<DBIO::MySQL::Storage::MariaDB>

=item *

Old: C<DBIx::Class::SQLMaker::MySQL>

=item *

New: C<DBIO::MySQL::SQLMaker>

=back

If C<DBIO-MySQL> is installed, core L<DBIO::Storage::DBI> can autodetect MySQL
DSNs and load the new storage class via the driver registry.

=head1 TESTING

Integration tests in this distribution use:

  DBIO_TEST_MYSQL_DSN
  DBIO_TEST_MYSQL_USER
  DBIO_TEST_MYSQL_PASS

SQLMaker-focused tests can run offline via L<DBIO::Test> with:

  storage_type => 'DBIO::MySQL::Storage'

Replicated-path tests can reuse the same harness with:

  replicated   => 1,
  storage_type => 'DBIO::MySQL::Storage'

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
