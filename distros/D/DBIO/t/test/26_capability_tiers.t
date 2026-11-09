use strict;
use warnings;
use Test::More;
use Test::Exception;
use DBIO::Test;
use DBIO::Test::Storage ();
use DBIO::Storage::DBI ();
use DBIO::Storage::DBI::Capabilities ();

# ADR 0041. The capability system has THREE tiers, and
# they are three different places:
#
#   1. the per-storage force      $storage->_use_X(0|1)   -- instance hash
#   2. the class declaration      __PACKAGE__->_use_X(0|1) -- package var, @ISA
#   3. the determination          sub _determine_supports_X -- per-$dbh probe
#
# The measurement: a driver declaring in tier 2 could not have its
# answer recovered: Class::Accessor::Grouped reads an instance slot with
# exists(), not defined(), so $storage->_use_X(undef) wrote a TOMBSTONE into
# tier 1 rather than clearing it. The tombstone shadowed the declaration for
# the life of the storage and the question fell through to tier 3, landing on
# core's conservative default. The driver's answer was unrecoverable, and the
# two documented declaration forms therefore behaved differently -- with
# neither document mentioning it.
#
# This file is the tripwire. If the two forms ever stop agreeing, or if a
# clear ever stops being a clear, these fail.

my $schema = DBIO::Test->init_schema;

# --- 1. the measurement, on both declaration forms -----------------------
#
# The bug was exactly one cell of this table: form A's force(undef) read 0.

{
  package T::CT::Declared;
  our @ISA = ('DBIO::Test::Storage');
  # form A -- ADR 0037 section 2's shape: a static class fact in tier 2
  __PACKAGE__->_use_supports_upsert(1);
}
{
  package T::CT::Determined;
  our @ISA = ('DBIO::Test::Storage');
  # form B -- the same fact expressed in tier 3
  sub _determine_supports_supports_upsert { 1 }
}

for my $form ( [ 'T::CT::Declared' => 'class-level _use_ (tier 2)' ],
               [ 'T::CT::Determined' => '_determine_supports_ (tier 3)' ] ) {
  my ($class, $label) = @$form;

  my $storage = $class->new($schema);

  is $storage->_use_supports_upsert, 1,
    "$label: fresh -- the driver's answer";

  $storage->_use_supports_upsert(0);
  is $storage->_use_supports_upsert, 0,
    "$label: forced off -- the caller overrides the driver";

  $storage->_use_supports_upsert(undef);
  is $storage->_use_supports_upsert, 1,
    "$label: force cleared -- the question goes back to the DRIVER, not to "
  . "core's default 0";

  # and the round trip survives repetition: clearing must not consume the
  # declaration, it must leave tier 2 exactly as it found it
  $storage->_use_supports_upsert(0);
  $storage->_use_supports_upsert(undef);
  is $storage->_use_supports_upsert, 1,
    "$label: a second force/clear cycle answers the same";
}

# --- 2. the two tiers are two slots --------------------------------------
#
# White-box on purpose. This is the fact the ticket turned on -- a force and a
# declaration written through the *same* accessor land in different places --
# and an assertion on the observable alone could not tell "the declaration
# survived" from "the declaration was rewritten to the forced value".

{
  my $storage = T::CT::Declared->new($schema);

  ok ! exists $storage->{_use_supports_upsert},
    'a fresh storage holds no tier-1 force -- the declaration is not copied '
  . 'into the instance';

  {
    no strict 'refs';
    is ${"T::CT::Declared::__cag__use_supports_upsert"}, 1,
      'the class declaration lives in the class, in a package variable';
  }

  $storage->_use_supports_upsert(0);
  ok exists $storage->{_use_supports_upsert},
    'forcing writes the instance -- tier 1';
  is $storage->{_use_supports_upsert}, 0, '... with the forced value';

  {
    no strict 'refs';
    is ${"T::CT::Declared::__cag__use_supports_upsert"}, 1,
      'and it leaves the class declaration alone -- forcing is per storage';
  }

  $storage->_use_supports_upsert(undef);
  ok ! exists $storage->{_use_supports_upsert},
    'clearing REMOVES the tier-1 slot. Assigning undef into it would leave a '
  . 'key that exists but is not defined, and get_inherited reads an instance '
  . 'with exists() -- that tombstone is the bug';
}

# --- 3. undef is not 0 ----------------------------------------------------
#
# The two must never collapse into each other: 0 is "this caller says no",
# undef is "this caller has no opinion". get_use_dbms_capability already
# reads undef as "ask the next tier", so undef could never have meant off.

{
  my $storage = T::CT::Declared->new($schema);

  $storage->_use_supports_upsert(0);
  is $storage->_use_supports_upsert, 0,
    'an explicit 0 force reads as 0, not as unset';

  # a second storage of the same class is untouched by the first one's force
  my $other = T::CT::Declared->new($schema);
  is $other->_use_supports_upsert, 1,
    'a force on one storage does not leak to another of the same class';
}

# --- 4. the base class's own class-level declaration ----------------------
#
# join_optimizer is the one capability core declares in tier 2 on the base
# class itself, so it is the real-world case: force it off on one storage and
# clear, and core's declaration must come back.

{
  my $storage = $schema->storage;

  is $storage->_use_join_optimizer, 1, 'join_optimizer is on by default';

  $storage->_use_join_optimizer(0);
  is $storage->_use_join_optimizer, 0, '... forced off for this storage';

  $storage->_use_join_optimizer(undef);
  is $storage->_use_join_optimizer, 1,
    '... and clearing restores core\'s declaration rather than falling '
  . 'through to _determine_supports_join_optimizer by accident';
}

# --- 5. tier 2 is inherited, and a force over an inherited declaration
#        clears back to it ----------------------------------------------

{
  package T::CT::Subclass;
  our @ISA = ('T::CT::Declared');
}

{
  is( T::CT::Subclass->_use_supports_upsert, 1,
    'a subclass inherits the declaration as a class method' );

  my $storage = T::CT::Subclass->new($schema);
  $storage->_use_supports_upsert(0);
  $storage->_use_supports_upsert(undef);
  is $storage->_use_supports_upsert, 1,
    'clearing on a subclass walks @ISA back to the declaring class';
}

# --- 6. a class invocant is unchanged -------------------------------------
#
# Only the instance slot needed the delete. get_inherited already tests
# defined() while it walks classes, so an undef declaration falls through by
# itself -- and a class has no hash to delete from.

{
  package T::CT::ClassClear;
  our @ISA = ('T::CT::Declared');
}

lives_ok { T::CT::ClassClear->_use_supports_upsert(undef) }
  'setting undef on a CLASS does not die';

is( T::CT::ClassClear->_use_supports_upsert, 1,
  '... and still reads the inherited declaration -- an undef package var is '
. 'already walked past' );

# --- 7. the determination tier is not poisoned by a force -----------------
#
# Forcing reads tier 1 and never consults tier 3, so a force must not leave a
# cached determination behind that outlives it.

{
  package T::CT::DeterminedOnly;
  our @ISA = ('DBIO::Test::Storage');
  sub _determine_supports_supports_if_exists { 1 }
}

{
  my $storage = T::CT::DeterminedOnly->new($schema);

  $storage->_use_supports_if_exists(0);
  is $storage->_use_supports_if_exists, 0, 'forced off';

  $storage->_use_supports_if_exists(undef);
  is $storage->_use_supports_if_exists, 1,
    'the determination still answers after a force was cleared';

  is $storage->_supports_supports_if_exists, 1,
    'and the _supports_ tier reads the same value directly';
}

# --- 8. a driver-declared capability before the rebless -------------------
#
# Core determines the driver lazily, and determination may move a declared
# storage to the class of its access path (ADR 0059; a schema always declares
# its driver, ADR 0067). The per-name accessors a driver installs on that
# class are, on a storage not determined yet, not methods at all -- core
# cannot install them in advance, because it does not know the name and has
# not chosen the class. That limitation is documented rather than mechanised;
# it is pinned here so it cannot change silently.
#
# What does work name-independently is the two-argument form underneath every
# _use_ accessor, and that is what a driver's POD should name.

{
  package T::CT::DriverStorage;
  our @ISA = ('DBIO::Storage::DBI');
  sub _adapt_to_access_path {
    my ($self, $dbd) = @_;
    bless $self, 'T::CT::DriverStorage::Path'
      if defined $dbd and $dbd eq 'FakeCapTiersDrv';
  }
  $INC{'T/CT/DriverStorage.pm'} = 1;
}
{
  package T::CT::DriverStorage::Path;
  our @ISA = ('T::CT::DriverStorage');
  __PACKAGE__->mk_group_accessors( dbms_capability     => '_supports_widgets' );
  __PACKAGE__->mk_group_accessors( use_dbms_capability => '_use_widgets' );
  sub _determine_supports_widgets { 1 }
}
DBIO::Storage::DBI->register_driver('FakeCapTiersDrv' => 'T::CT::DriverStorage');

sub _fresh_undetermined {
  my $storage = T::CT::DriverStorage->new($schema);
  $storage->connect_info([ 'dbi:FakeCapTiersDrv:', '', '' ]);
  $storage;
}

{
  my $storage = _fresh_undetermined();

  throws_ok { $storage->_use_widgets(1) }
    qr/\QCan't locate object method "_use_widgets"\E/,
    'the per-name accessor of a driver-declared capability does not exist '
  . 'before the rebless -- the documented limitation';

  is ref($storage), 'T::CT::DriverStorage',
    '... and the failed call did not determine the driver either';
}

{
  # the getter is on DBIO::Storage::DBI's driver-determination list, so asking
  # by name reblesses first and then answers from the driver
  my $storage = _fresh_undetermined();

  is $storage->get_use_dbms_capability('_use_widgets'), 1,
    'the two-argument getter answers a driver-declared capability before the '
  . 'rebless';
  isa_ok $storage, 'T::CT::DriverStorage::Path',
    '... because asking determined the driver';
  is $storage->_use_widgets, 1,
    'and the per-name accessor works from here on';
}

{
  # the setter writes tier 1, which the driver's own accessor reads after the
  # rebless -- and clearing it there hands the question back to the driver
  # exactly as it does for a core capability
  my $storage = _fresh_undetermined();

  $storage->set_use_dbms_capability('_use_widgets', 0);
  is ref($storage), 'T::CT::DriverStorage',
    'the two-argument setter does not connect or determine anything';

  is $storage->get_use_dbms_capability('_use_widgets'), 0,
    'the force set before the rebless is honoured after it';

  $storage->set_use_dbms_capability('_use_widgets', undef);
  is $storage->get_use_dbms_capability('_use_widgets'), 1,
    'and clearing through the two-argument form hands the question back to '
  . 'the driver too';
}

done_testing;
