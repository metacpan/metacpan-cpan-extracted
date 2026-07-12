use strict;
use warnings;

use Test::More;

use DBIO::Test::Storage;

# Exercises the DBIO::FilterColumn SYNOPSIS and "EXAMPLE OF USE" blocks:
# filter_to_storage / filter_from_storage must actually run on the way
# in and out of storage, not just be recorded as configuration. Per
# CLAUDE.md, core tests use only DBIO::Test::Storage (mock) -- never a
# real DB -- so the "round trip" here is: capture the bound INSERT value
# (to_storage direction) and inflate a mocked raw SELECT row (from_storage
# direction).

{
  package TestDBIO::FilterCol::Schema;
  use base 'DBIO::Schema';
}

{
  package TestDBIO::FilterCol::Schema::Result::Item;
  use base 'DBIO::Core';

  __PACKAGE__->load_components(qw/FilterColumn/);

  __PACKAGE__->table('item');
  __PACKAGE__->add_columns(
    id => {
      data_type => 'integer',
      is_auto_increment => 1,
    },
    # SYNOPSIS example: money stored in pennies, used in dollars
    money => {
      data_type => 'integer',
    },
    # EXAMPLE OF USE: boolean column that only filters on the way to
    # storage -- filter_from_storage is deliberately not specified
    my_boolean_column => {
      data_type => 'integer',
      is_nullable => 1,
    },
  );
  __PACKAGE__->set_primary_key('id');

  __PACKAGE__->filter_column(money => {
    filter_to_storage   => 'to_pennies',
    filter_from_storage => 'from_pennies',
  });

  __PACKAGE__->filter_column(my_boolean_column => {
    filter_to_storage => sub { $_[1] ? 1 : 0 },
  });

  sub to_pennies   { $_[1] * 100 }
  sub from_pennies { $_[1] / 100 }
}

TestDBIO::FilterCol::Schema->register_class(Item => 'TestDBIO::FilterCol::Schema::Result::Item');

my $schema  = TestDBIO::FilterCol::Schema->connect(sub { });
$schema->storage(DBIO::Test::Storage->new($schema));
my $storage = $schema->storage;

subtest 'SYNOPSIS: money filter round-trips to and from storage' => sub {
  $storage->reset_captured;

  my $item = $schema->resultset('Item')->create({ money => 2.5 });

  my ($insert) = grep { $_->{op} eq 'insert' } $storage->captured_queries;
  ok $insert, 'insert was captured';
  is $insert->{bind}[0][1], 250, 'filter_to_storage converted 2.5 dollars to 250 pennies on the way in';

  # The in-memory object also reflects the storage-shaped raw value via
  # get_column, and the app-shaped value via the filtered accessor.
  is $item->get_column('money'), 250, 'get_column returns the raw (to-storage) value after insert';
  is $item->money, 2.5, 'filtered accessor still returns the app-shaped value';

  # Now simulate loading a row fresh from storage: raw pennies in, no
  # filtering applied yet until the filtered accessor/get_filtered_column
  # is used.
  $storage->reset_captured;
  $storage->mock(qr/SELECT.*FROM "item"/i, [[ 1, 500, undef ]]);

  my $loaded = $schema->resultset('Item')->search({ id => 1 })->next;
  is $loaded->get_column('money'), 500, 'raw storage value is untouched by default';
  is $loaded->money, 5, 'filter_from_storage converted 500 pennies to 5 dollars on the way out';
};

subtest 'EXAMPLE OF USE: filter_to_storage without filter_from_storage' => sub {
  $storage->reset_captured;

  my $true_item  = $schema->resultset('Item')->create({ money => 0, my_boolean_column => 'yes' });
  my ($ins1) = grep { $_->{op} eq 'insert' } $storage->captured_queries;
  my ($bind1) = grep { $_->[0]{dbic_colname} eq 'my_boolean_column' } @{ $ins1->{bind} };
  is $bind1->[1], 1, 'truthy perl value is normalized to numeric 1 on the way to storage';

  $storage->reset_captured;
  my $false_item = $schema->resultset('Item')->create({ money => 0, my_boolean_column => undef });
  my ($ins2) = grep { $_->{op} eq 'insert' } $storage->captured_queries;
  my ($bind2) = grep { $_->[0]{dbic_colname} eq 'my_boolean_column' } @{ $ins2->{bind} };
  is $bind2->[1], 0, 'undef/false perl value is normalized to numeric 0 on the way to storage';

  # No filter_from_storage was declared, so a raw value read back from
  # storage passes straight through unfiltered, per the component's docs.
  $storage->reset_captured;
  $storage->mock(qr/SELECT.*FROM "item"/i, [[ 2, 0, 1 ]]);
  my $loaded = $schema->resultset('Item')->search({ id => 2 })->next;
  is $loaded->my_boolean_column, 1, 'without filter_from_storage the raw DB value passes through unfiltered';
};

done_testing;
