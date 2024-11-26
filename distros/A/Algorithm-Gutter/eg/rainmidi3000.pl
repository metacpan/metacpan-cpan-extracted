#!/usr/bin/env perl
# rainmidi3000.pl - an example Algorithm::Gutter script, where random
# holes in a gutter either produce MIDI note events or toggle other
# holes on or off over time, as fed by changing amounts of rainfall.
# There are lots of things to TWEAK.
use v5.26.0;
use Algorithm::Gutter;
use List::Util 'shuffle';
use MIDI;

my $out_file = shift // 'out.midi';
my $ch       = 0;                     # MIDI channel (9 for drums)
my $tick     = 32;                    # default duration (dtime)

# So you can figure out how things were wired up if you actually get
# good results from this thing.
my $seed = shift;
srand $seed if defined $seed;
say "SEED ", srand;

# See MIDI::Event and the MIDI specification.
my @events = (
    [ text_event   => 0, "RAIN-MIDI 3000" ],
    [ patch_change => 0, $ch, 11 ],
    [ set_tempo    => 0, 450_000 ],
);

my $gobj  = Algorithm::Gutter->new( rain => \&water );
my $glist = $gobj->gutter;

# The 'undef' are replaced with togglers, while the numbers are used to
# generate MIDI events with the given pitch number. TWEAK
my $nbuckets = 32;
my @pitches  = shuffle( (undef) x 7,
    55, 56, 60, 61, 65, 67, 68, 72, 73, 77, 79, 80, 84 );
my $nholes = @pitches;

# Randomly allocate the toggler and pitch-generating cells. Planning
# where these go might get you better results?
my $total  = $nbuckets;
my $remain = $nholes;
for ( 1 .. $nbuckets ) {
    my $cell = Algorithm::Gutter::Cell->new( amount => int rand 4, );
    if ( rand(1.0) < ( $remain / $total ) ) {
        $cell->enabled = 1;
        die "not enough pitches??\n" unless @pitches;
        my $p = shift @pitches;
        if ( defined $p ) {
            $cell->set_update( \&pitch );
            # TWEAK larger values need more rainfall to trigger
            $cell->threshold = 2 + int( rand 4 + rand 4 + rand 4 );
        } else {
            $cell->set_update( \&toggle );
            $cell->threshold = 4 + int( rand 6 + rand 6 );
        }
        $cell->context = $p;
        last if --$remain <= 0;
    }
    push @$glist, $cell;
    $total--;
}

# Wire up the togglers to toggle a random toggler or pitch generator
# cell, if possible.
my @active = shuffle grep $_->enabled, @$glist;
for my $cell ( shuffle @$glist ) {
    unless ( defined $cell->context ) {
        if (@active) {
            $cell->context = shift @active;
            $cell->enabled = coinflip();
        } else {
            $cell->enabled   = 0;
            $cell->threshold = ~0;
        }
    }
}

# This runs for a while (or for too bloody long) so one can get a sense
# of how much the varied rainfall and etc. change the output.
my $offset = 0;
for my $turn ( 1 .. 3000 ) {
    $gobj->rain;
    my @pitches = $gobj->drain(0);
    if (@pitches) {
        sound( $offset, @pitches );
    } else {
        $offset += $tick + ticknoise();
    }
    $gobj->slosh;
}

MIDI::Opus->new(
    { format => 0, ticks => 96, tracks => make_track() } )
  ->write_to_file($out_file);

########################################################################
#
# SUBROUTINES

sub coinflip { int rand 2 }

sub make_track () { [ MIDI::Track->new( { events => \@events } ) ] }

sub pitch { $_[0]->context }

# Generate MIDI events for one or more pitches happening at the
# same time.
my $at_most = 4;

sub sound {
    my ( $offset, @pitch ) = @_;
    my $most = $at_most;
    for my $n (@pitch) {
        push @events, [ note_on => $offset, $ch, $n, velonoise() ];
        $offset = 0;
        last if $most-- <= 0;
    }
    # Note duration. This could be shortened and an $offset on the next
    # start event added elsewhere to produce staccato notes, or you can
    # get much the same effect by using a small $tick value and not
    # having much rainfall.
    $offset = $tick + ticknoise();
    $most   = $at_most;
    for my $n (@pitch) {
        push @events, [ note_off => $offset, $ch, $n, 0 ];
        $offset = 0;
        last if $most-- <= 0;
    }
}

# Probably one would need a larger tick value and then to fiddle with
# the tempo if one wants more noise here, and then to roll rand two or
# more times to get a more normal distribution around 0?
sub ticknoise { int( rand 3 ) - 1 }

sub toggle {
    my $ctx = $_[0]->context;
    $ctx->enabled ^= 1 if defined $ctx;
    return;
}

sub velonoise { 96 + int( rand 6 + rand 6 + rand 6 ) }

# Add rain water to random cells, with complications. How much rain is
# necessary will depend on the amount of rain, how many cells there
# are, what the thresholds are, etc. and thus all such knobs may
# require fiddling around with and balancing against one another. Even
# more complicated would be to return the amount of water drained and
# feed those values into different gutters... one could also simply
# teleport the water around, as this abstraction need not follow
# reality too closely.
sub water {
    my ( $gutter, $stash ) = @_;
    state $change = 0;
    state $drops  = 3 + int rand 6;
    my $len = @$gutter;
    my $n   = $drops * 2;
    for my $i ( 0 .. $len - 1 ) {
        if ( rand(1.0) < ( $n / $len ) ) {
            $gutter->[$i]->amount += 2;    # TWEAK important knob
            last if --$n <= 0;
        }
        $len--;
    }
    if ( ++$change == 1 ) {
        if ( rand(1.0) < ( $drops / 10 ) ) {
            $drops--;
        } else {
            $drops++;
        }
        $change = 0;
    }
}
