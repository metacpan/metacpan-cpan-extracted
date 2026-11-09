use strict;
use warnings;

use Test::More;

use DBIO::UUIDColumns;

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

TestDBIO::UUIDCol::Schema->storage_type('+DBIO::Test::Storage');
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

subtest 'default generator makes version 4 UUIDs in canonical lowercase form' => sub {
  my $v4_re = qr/^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/;
  my %seen;
  my $bad = 0;
  for (1 .. 1000) {
    my $u = TestDBIO::UUIDCol::Schema::Result::Artist->get_uuid;
    $bad++ unless $u =~ $v4_re;
    $seen{$u}++;
  }
  is $bad, 0, '1000 values: version nibble 4, variant bits 10xx, lowercase canonical';
  is scalar(keys %seen), 1000, '1000 values are pairwise distinct';
  is(TestDBIO::UUIDCol::Schema::Result::Artist->uuid_class, 'DBIO::UUIDColumns',
    'the built-in generator is the default uuid_class');
};

subtest 'uuid_class selects Data::UUID explicitly' => sub {
  plan skip_all => 'Data::UUID not installed' unless eval { require Data::UUID; 1 };
  my $class = 'TestDBIO::UUIDCol::Schema::Result::Artist';
  $class->uuid_class('Data::UUID');
  is $class->uuid_class, 'Data::UUID', 'backend switched';
  like $class->get_uuid, $uuid_re, 'Data::UUID value is UUID-shaped';
  $class->uuid_class('DBIO::UUIDColumns');
};

done_testing;
