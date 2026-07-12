use strict;
use warnings;

use Test::More;

BEGIN {
  # UUIDColumns dies at load time if none of Data::UUID / UUID / UUID::Random
  # is installed (none of them are cpanfile dependencies of core -- see
  # DBIO::UUIDColumns::_find_uuid_module). Skip cleanly rather than fail.
  unless (eval { require DBIO::UUIDColumns; 1 }) {
    plan skip_all => "No UUID backend (Data::UUID / UUID / UUID::Random) installed: $@";
  }
}

use DBIO::Test::Storage;

# Exercises the DBIO::UUIDColumns SYNOPSIS: a column flagged with
# uuid_on_create => 1 gets a freshly generated UUID on insert, and an
# already-supplied value is respected (not overwritten). Mock-only per
# CLAUDE.md -- the UUID is asserted against the captured INSERT bind
# value, never against a real database.

{
  package TestDBIO::UUIDCol::Schema;
  use base 'DBIO::Schema';
}

{
  package TestDBIO::UUIDCol::Schema::Result::Artist;
  use base 'DBIO::Core';

  __PACKAGE__->load_components(qw/UUIDColumns/);

  __PACKAGE__->table('artist');
  __PACKAGE__->add_columns(
    artist_id => { data_type => 'varchar', size => 36, uuid_on_create => 1 },
    name      => { data_type => 'varchar', size => 100 },
  );
  __PACKAGE__->set_primary_key('artist_id');
}

TestDBIO::UUIDCol::Schema->register_class(Artist => 'TestDBIO::UUIDCol::Schema::Result::Artist');

my $schema  = TestDBIO::UUIDCol::Schema->connect(sub { });
$schema->storage(DBIO::Test::Storage->new($schema));
my $storage = $schema->storage;

my $uuid_re = qr/^[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}$/;

subtest 'uuid_on_create populates an unset column with a UUID-shaped value' => sub {
  $storage->reset_captured;

  my $artist = $schema->resultset('Artist')->create({ name => 'Foo' });

  like $artist->artist_id, $uuid_re, 'in-memory object has a UUID-shaped artist_id after create';

  my ($insert) = grep { $_->{op} eq 'insert' } $storage->captured_queries;
  ok $insert, 'insert was captured';
  my ($bind) = grep { $_->[0]{dbic_colname} eq 'artist_id' } @{ $insert->{bind} };
  like $bind->[1], $uuid_re, 'the UUID actually bound in the INSERT is UUID-shaped';
};

subtest 'an existing value is respected, not overwritten' => sub {
  $storage->reset_captured;

  my $artist = $schema->resultset('Artist')->create({ name => 'Bar', artist_id => 'fixed-id' });
  is $artist->artist_id, 'fixed-id', 'explicit artist_id survives insert() unchanged';

  my ($insert) = grep { $_->{op} eq 'insert' } $storage->captured_queries;
  my ($bind) = grep { $_->[0]{dbic_colname} eq 'artist_id' } @{ $insert->{bind} };
  is $bind->[1], 'fixed-id', 'the bound INSERT value is the caller-supplied id, not a generated UUID';
};

subtest 'each row gets its own UUID' => sub {
  my $a = $schema->resultset('Artist')->create({ name => 'A' });
  my $b = $schema->resultset('Artist')->create({ name => 'B' });
  isnt $a->artist_id, $b->artist_id, 'two rows created without an explicit id get different UUIDs';
};

done_testing;
