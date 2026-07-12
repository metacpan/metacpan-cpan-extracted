use strict;
use warnings;

use Test::More;

use DBIO::Test::Storage;
use DBIO::Storage::DBI::AutoCast;

# Backs the DBIO::Storage::DBI::AutoCast SYNOPSIS:
#
#   $schema->storage->auto_cast(1);
#
# ...which makes bound placeholders emit CAST(? AS <native type>) in the
# generated SQL (needed by RDBMS/DBD combos that reject untyped placeholders,
# e.g. FreeTDS/Sybase).
#
# MOCK LIMIT (documented): the rewrite only fires for binds whose data_type
# resolves to a native type via the storage's _native_data_type, which every
# real AutoCast-using driver overrides (base returns undef -> no CAST). The
# mock cannot know a real backend's type map, so this test composes AutoCast
# onto the fake storage and supplies a stand-in _native_data_type (an
# uppercasing identity map, exactly the *shape* a driver provides). What is
# faithfully asserted is AutoCast's own contract: with auto_cast on, every
# typed placeholder is wrapped as CAST(? AS TYPE); with it off, none are.

{
  package DBIO::Test::Storage::AutoCastProbe;
  use base qw/DBIO::Test::Storage DBIO::Storage::DBI::AutoCast/;
  use mro 'c3';

  # Stand in for a driver's native type map so the CAST rewrite is observable.
  sub _native_data_type {
    my ($self, $type) = @_;
    return undef unless defined $type;
    return uc $type;
  }
}

{
  package TestDBIO::AutoCast::Schema;
  use base 'DBIO::Schema';
}
{
  package TestDBIO::AutoCast::Schema::Result::Widget;
  use base 'DBIO::Core';
  __PACKAGE__->table('widget');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer', is_auto_increment => 1 },
    name => { data_type => 'varchar', size => 255 },
    qty  => { data_type => 'integer' },
  );
  __PACKAGE__->set_primary_key('id');
}

TestDBIO::AutoCast::Schema->register_class(Widget => 'TestDBIO::AutoCast::Schema::Result::Widget');

my $schema  = TestDBIO::AutoCast::Schema->connect(sub { });
my $storage = DBIO::Test::Storage::AutoCastProbe->new($schema);
$schema->storage($storage);

isa_ok $storage, 'DBIO::Storage::DBI::AutoCast', 'the probe storage composes AutoCast';

subtest 'auto_cast off (default): plain placeholders, no CAST' => sub {
  ok !$storage->auto_cast, 'auto_cast defaults off';
  $storage->reset_captured;

  $schema->resultset('Widget')->create({ name => 'gizmo', qty => 7 });

  my ($insert) = grep { $_->{op} eq 'insert' } $storage->captured_queries;
  ok $insert, 'insert captured';
  unlike $insert->{sql}, qr/CAST\(/i, 'no CAST(...) wrapping when auto_cast is off';
  like $insert->{sql}, qr/VALUES\s*\(\s*\?/i, 'plain ? placeholders are used';
};

subtest 'auto_cast on: typed placeholders emit CAST(? AS <type>)' => sub {
  $storage->auto_cast(1);
  ok $storage->auto_cast, 'auto_cast enabled';
  $storage->reset_captured;

  $schema->resultset('Widget')->create({ name => 'gadget', qty => 42 });

  my ($insert) = grep { $_->{op} eq 'insert' } $storage->captured_queries;
  ok $insert, 'insert captured';
  like $insert->{sql}, qr/CAST\(\?\s+AS\s+VARCHAR\)/i,
    'the varchar bind is wrapped as CAST(? AS VARCHAR)';
  like $insert->{sql}, qr/CAST\(\?\s+AS\s+INTEGER\)/i,
    'the integer bind is wrapped as CAST(? AS INTEGER)';
  unlike $insert->{sql}, qr/VALUES\s*\(\s*\?\s*,/i,
    'no bare ? placeholder survives in the VALUES list';

  $storage->auto_cast(0);
};

subtest 'connect_call_set_auto_cast flips the flag on' => sub {
  $storage->auto_cast(0);
  $storage->connect_call_set_auto_cast;
  ok $storage->auto_cast, 'connect_call_set_auto_cast turned auto_cast on';
  $storage->auto_cast(0);
};

done_testing;
