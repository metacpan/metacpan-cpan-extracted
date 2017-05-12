use Test::More tests => 27;

# TODO: More tests for disconnection syntax. Make sure the correct things
# always get disconnected. More tests for arrays of signal names.

my @slot_got = ();
my $rc;

sub got_slot {
  push @slot_got, @_;
}

sub get_got {
  my $got = join( ' ', sort @slot_got );
  @slot_got = ();
  return $got;
}

sub get_err {
  my $err = $@;
  # Tidy up error message
  $err =~ s{ \n .* }{}xms;
  $err =~ s{ \s+ at \s+ \S+ \s+ line \s+ \d+ \s* $ }{}xms;
  return $err;
}

package My::Class::One;
use Class::Std;
use Class::Std::Slots;
{
  signals qw(
   my_signal
   other_signal
  );

  sub my_slot {
    my $self = shift;
    main::got_slot( 'my_slot' );
  }

  sub other_slot {
    my $self = shift;
    main::got_slot( 'other_slot' );
    # Guarded with has_slots just to make sure it doesn't
    # make a difference. Don't do this in real code if the
    # signal call is computationally cheap.
    $self->other_signal if $self->has_slots( 'other_signal' );
  }

  sub do_stuff {
    my $self = shift;
    $self->my_signal;    # send signal
  }
}

package My::Class::Two;
use Class::Std;
use Class::Std::Slots;
{
  signals qw(
   another_signal
  );

  sub another_slot {
    my $self = shift;
    main::got_slot( 'another_slot' );
    $self->another_signal;
  }
}

package My::Class::Two::More;
use base qw(My::Class::Two);
use Class::Std;
use Class::Std::Slots;
{
  signals qw(
   unique_to_more
  );

  sub more_slot {
    my $self = shift;
    main::got_slot( 'more_slot' );
    $self->unique_to_more;
  }
}

package main;

my $ob1a = My::Class::One->new();
my $ob1b = My::Class::One->new();
my $ob2  = My::Class::Two->new();
my $ob2m = My::Class::Two::More->new();

ok( !$ob1a->has_slots( 'my_signal' ), 'No slots' );

# No signal yet
$ob1a->do_stuff;
is( get_got, '', 'No slots' );

# Connect to a slot in another class
$ob1a->connect( 'my_signal', $ob2, 'another_slot' );

ok( $ob1a->has_slots( 'my_signal' ),     'Has slots' );
ok( !$ob1b->has_slots( 'my_signal' ),    'No slots (2)' );
ok( !$ob1a->has_slots( 'other_signal' ), 'No slots (3)' );
ok( $ob1a->has_slots( [ 'other_signal', 'my_signal' ] ),
  'Has multiple slots' );

$ob1a->do_stuff;
is( get_got, 'another_slot', 'One slot' );

$ob1a->connect( 'my_signal', sub { got_slot( 'ANON' ); } );

$ob1a->do_stuff;
is( get_got, 'ANON another_slot', 'Two slots' );

$ob1b->do_stuff;
is( get_got, '', 'No slots, other obj' );

# Delete named connection
$ob1a->disconnect( 'my_signal', $ob2, 'another_slot' );

$ob1a->do_stuff;
is( get_got, 'ANON', 'Deleted named slot, anon only' );

$ob1a->disconnect();

$ob1a->do_stuff;
is( get_got, '', 'Deleted everything' );

# More complex connections
$ob1a->connect( ['my_signal'], $ob1b, 'my_signal' );
$ob1b->connect( 'my_signal', $ob2m, 'more_slot' );

$ob1a->my_signal;    # Fire directly
is( get_got, 'more_slot', 'Chained call' );

# Test some errors
eval { $ob1a->connect( 'my_signal', $ob2m, 'bogus_slot' ); };

is(
  get_err,
  "Slot 'bogus_slot' not handled by My::Class::Two::More",
  'Bad slot name'
);

eval { $ob1a->connect( 'my_signal', my $not_an_obj, 'some_slot' ); };

is(
  get_err,
  'Usage: $source->connect($sig_name, $dst_obj, $dst_method [, { options }])',
  'Bad object'
);

eval { $ob1a->connect( 'my_signal', $ob2 ); };

is(
  get_err,
  'Usage: $source->connect($sig_name, $dst_obj, $dst_method [, { options }])',
  'Missing method'
);

eval { $ob1a->connect( 'bad signal name', $ob2m, 'more_slot' ); };

is(
  get_err,
  "Invalid signal name 'bad signal name'",
  'Bad signal name'
);

eval { $ob2->connect( 'unique_to_more', $ob1a, 'my_slot' ); };

is(
  get_err,
  "Signal 'unique_to_more' undefined",
  'Signal only in subclass'
);

eval { $ob1a->connect( 'my_signal', $ob2, 'more_slot' ); };

is(
  get_err,
  "Slot 'more_slot' not handled by My::Class::Two",
  'Slot only in subclass'
);

# Make sure this test still works after all those errors
$ob1a->my_signal;    # Fire directly
is( get_got, 'more_slot', 'Still works' );

# Make a simple circular connection
$ob2m->connect( 'unique_to_more', $ob2m, 'more_slot' );

eval { $ob2m->unique_to_more; };

is(
  get_err,
  "Attempt to re-enter signal 'unique_to_more'",
  'Simple circularity'
);
is( get_got, 'more_slot', 'Simple circularity results' );

for ( $ob1a, $ob1b, $ob2, $ob2m ) {
  $_->disconnect();
}

# Trigger all the signals...
for ( $ob1a, $ob1b ) {
  $_->my_signal;
  $_->other_signal;
}

$ob2->another_signal;
$ob2m->unique_to_more;

# ...and make sure nothing happened
is( get_got, '', 'All disconnected' );

# Make a more complex loop
$ob1a->connect( 'my_signal',    $ob1b, 'other_slot' );
$ob1b->connect( 'other_signal', $ob2,  'another_slot' );
$ob2->connect( 'another_signal', $ob2m, 'more_slot' );
$ob2m->connect( 'unique_to_more', $ob1a, 'my_signal' );

eval { $ob1a->my_signal; };

is(
  get_err,
  "Attempt to re-enter signal 'my_signal'",
  'Complex circularity'
);
is(
  get_got,
  'another_slot more_slot other_slot',
  'Complex circularity results'
);

# Check that has_slots can be called on an undeclared signals

eval { $rc = $ob1a->has_slots( 'made_up_signal_name' ); };

ok( !$rc, 'has_slots with made up signal name' );
is( get_err, '', 'has_slots with made up signal name - not an error' );

for ( $ob1a, $ob1b, $ob2, $ob2m ) {
  $_->disconnect();
}

$ob1a->connect( 'made_up_signal_name', $ob1b, 'other_slot',
  { undeclared => 1 } );
$ob1a->emit_signal( 'made_up_signal_name' );

is( get_got, 'other_slot', 'Synthetic signal name' );
