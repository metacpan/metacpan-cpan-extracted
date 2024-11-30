#!/usr/bin/env perl
# rainmidi3000.pl - an example Algorithm::Gutter script, where random
# holes in a gutter either produce MIDI note events or toggle other
# holes on or off over time, as fed by changing amounts of rainfall.
# There are lots of things to TWEAK.
use v5.26.0;
use Algorithm::Gutter 0.02;
use Data::Dumper;
use List::Util 'shuffle';
use MIDI;

my $out_file = shift // 'out.midi';
my $ch       = 0;                     # MIDI channel (9 for drums)
my $tick     = 32;                    # default duration (dtime)

# So you can figure out how things were wired up if you actually get
# good results from this thing, unless you are on OpenBSD, or this code
# is somehow incorrect.
my $seed = shift;
if ( defined $seed ) {
    srand $seed;
} else {
    say "SEED ", srand;
}

# See MIDI::Event and the MIDI specification.
my @events = (
    [ text_event => 0, 'RAIN-MIDI 3000 ][' ],
    #[ patch_change => 0, $ch, 11 ],
    [ set_tempo => 0, 450_000 ],
);

my $gobj  = Algorithm::Gutter->new( rain => \&water );
my $glist = $gobj->gutter;

# The 'undef' are replaced with togglers, while the numbers are used to
# generate MIDI events with the given pitch number. Random pitches
# better suit random drum soundfonts. TWEAK
my $nbuckets = 32;
my @pitches  = shuffle( (undef) x 5, map getapitch(), 1 .. 13 );
#my @pitches = shuffle( (undef) x 5,
#    55, 56, 60, 61, 65, 67, 68, 72, 73, 77, 79, 80, 84 );
die "too many pitches\n" if @pitches > $nbuckets;
my $nholes = @pitches;

# Randomly allocate the toggler and pitch-generating cells. Planning
# where these go might get you better results?
{
    my $total  = $nbuckets;
    my $remain = $nholes;
    my $id     = 0;
    for ( 1 .. $nbuckets ) {
        my $cell = Algorithm::Gutter::Cell->new( amount => 0, id => $id++ );
        push @$glist, $cell;
        if ( rand(1.0) < ( $remain / $total ) ) {
            $cell->enabled = 1;
            die "not enough pitches??\n" unless @pitches;
            my $p = shift @pitches;
            if ( defined $p ) {
                $cell->update = \&pitch;
                # TWEAK larger values need more rainfall to trigger
                $cell->threshold = 4 + int( rand 6 + rand 6 + rand 6 );
                $cell->context->{pitch} = $p;
            } else {
                $cell->update    = \&toggle;
                $cell->threshold = 4 + int( rand 2 + rand 2 + rand 2 );
            }
            last if $remain-- <= 0;
        }
        $total--;
    }
}

# Wire up the togglers to toggle a random toggler or pitch generator
# cell, if possible.
my @targets = shuffle grep { $_->enabled } @$glist;
for my $cell ( shuffle @$glist ) {
    unless ( defined $cell->context ) {
        if (@targets) {
            $cell->context->{toggles} = shift @targets;
            $cell->enabled = coinflip();
        } else {
            ( $cell->enabled, $cell->threshold, $cell->update ) =
              ( 0, ~0, undef );
        }
    }
}

# What thing did we wire up? Some way to visualize this over time might
# also help direct one towards better wirings?
show_wiring($glist);

{
    # TWEAK fewer slosh iterations makes the fluid more viscous and thus
    # less able to spread out to adjacent cells
    #my $slosh_iters;
    my $slosh_iters = 2;
    my %slosh;

    my $offset = 0;
    for my $turn ( 1 .. 128 ) {
        $gobj->rain;
        # TWEAK whether to drain all the fluid (1) or only up to the
        # threshold (0) but whether this makes a difference depends on
        # how much rain is being added, etc
        my @pitches = $gobj->drain(0);
        if (@pitches) {
            sound( $offset, @pitches );
        } else {
            $offset += $tick + ticknoise();
        }
        my $r = $gobj->slosh( $slosh_iters // ~0 );
        unless ( defined $slosh_iters ) {
            $slosh{$r}++;
        }
    }
    unless ( defined $slosh_iters ) {
        warn Data::Dumper->Dump( [ \%slosh ], ['slosh_iters'] );
    }
}

MIDI::Opus->new(
    { format => 0, ticks => 96, tracks => make_track() } )
  ->write_to_file($out_file);

########################################################################
#
# SUBROUTINES

sub coinflip { int rand 2 }

# This is for when you want random pitches, possibly when using a drum
# SountFont and to select from random drum samples. The MIDI number
# range may well need to be fiddled with. Softlocks if you try to
# request too many pitches from it, so don't do that.
{
    my %seen;

    sub getapitch {
        my $p;
        do {
            $p = 24 + int rand( 77 - 24 );
        } while exists $seen{$p};
        $seen{$p} = 1;
        return $p;
    }
}

sub make_track () { [ MIDI::Track->new( { events => \@events } ) ] }

sub pitch { $_[0]->context->{pitch} }

sub show_wiring {
    my ($gutter) = @_;
    for my $cell (@$gutter) {
        my $s = sprintf '% 3d ', $cell->id;
        if ( defined $cell->update ) {
            $s .= join ' ', $cell->enabled ? '+' : '-', sprintf '% 3d',
              $cell->threshold;
            my $c = $cell->context;
            if ( $cell->update == \&pitch ) {
                $s .= ' MIDI -> ' . $cell->context->{pitch};
            } else {
                $s .= ' TOGGLE #' . $cell->context->{toggles}->id;
            }
        }
        say $s;
    }
}

# Generate MIDI events for one or more pitches happening at the
# same time.
sub sound {
    my ( $offset, @pitch ) = @_;
    # TWEAK limit how notes can sound at the same time. Note choice will
    # depend on how the pitches get shuffled into the gutter.
    my $at_most = 4;
    my $left    = $at_most;
    for my $n (@pitch) {
        push @events, [ note_on => $offset, $ch, $n, velonoise() ];
        $offset = 0;
        last unless --$left;
    }
    # Note duration. This could be shortened and an $offset on the next
    # start event added elsewhere to produce staccato notes, or you can
    # get much the same effect by using a small $tick value and not
    # having much rainfall.
    $offset = $tick + ticknoise();
    $left   = $at_most;
    for my $n (@pitch) {
        push @events, [ note_off => $offset, $ch, $n, 0 ];
        $offset = 0;
        last unless --$left;
    }
}

# Probably one would need a larger tick value and then to fiddle with
# the tempo if one wants more noise here, and then to roll rand two or
# more times to get a more normal distribution around 0?
sub ticknoise { int( rand 3 ) - 1 }

sub toggle {
    $_[0]->context->{toggles}->enabled ^= 1;
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
    my $drops = 9 + int( rand 3 + rand 3 + rand 3 );
    my $len   = @$gutter;
    my $n     = $drops * 2;
    for my $i ( 0 .. $len - 1 ) {
        if ( rand(1.0) < ( $n / $len ) ) {
            $gutter->[$i]->amount += 4;    # TWEAK important knob
            last if --$n <= 0;
        }
        $len--;
    }
}
