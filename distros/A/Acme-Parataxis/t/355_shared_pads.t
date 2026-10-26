use v5.40;
use blib;
use Acme::Parataxis qw[async fiber yield];
use Acme::Parataxis::Channel;
use Test2::V1 -ipP;
$|++;

# Regression for the shared-pad wipe: CvDEPTH is one counter per CV, and every fiber that parks
# inside Channel::get leaves a live frame (and pad) behind in the shared PadList. When shallower
# frames leave, CvDEPTH dips below the deepest parked frame, and the next entry used to land on a
# parked frame's pad and overwrite its $self, @_, and my lexicals in place (fields, being
# instance-backed, survived; $self did not, so the victim died with an undefined receiver).
#
# Choreography: A, B, C, D park in get in that order; wake A and C so both leave and the depths
# dip; let both re-enter get (this is where C used to steal D's pad); wake C again so it vacates;
# then wake the victim D and the untouched control B. Every fiber must come back with its
# lexical, its own value, and no error.
our ( $entered, $left, $goA, $goC ) = ( 0, 0, 0, 0 );
our %REPORT;

sub report ( $name, $lex, $got, $err ) {
    $REPORT{$name} = [ $lex, defined $got ? $got : 'UNDEF', $err || '' ];
}

# Spin the scheduler until $cond holds, bounded so a condition that can never become true dies
# instead of hanging the suite.
sub spin ( $cond, $what ) {
    for ( 1 .. 5_000 ) { return if $cond->(); yield }
    die "timed out waiting for $what";
}

# One park in Channel::get, then report what survived the park.
sub single ( $ch, $ready_ref, $name ) {
    my $lex = "lex:$name";
    $$ready_ref = 1;
    my ( $got, $err );
    lives { $got = $ch->get } or $err = $@;
    report( $name, $lex, $got, $err );
}

# Park, leave on wake, wait for a go flag, park again, report. The two-phase park is what makes a
# fiber both vacate its pad and later re-enter the shared CV at a depth someone else may hold.
sub staged ( $ch1, $ch2, $ready_ref, $go_ref, $name ) {
    my $lex = "lex:$name";
    $$ready_ref = 1;
    eval { $ch1->get };
    $left++;
    spin( sub {$$go_ref}, "the go flag for $name" );
    $entered++;
    my ( $got, $err );
    lives { $got = $ch2->get } or $err = $@;
    report( $name, $lex, $got, $err );
}
my $base = Acme::Parataxis::get_live_fiber_count();
my $chA1 = Acme::Parataxis::Channel->new( capacity => 4 );
my $chA2 = Acme::Parataxis::Channel->new( capacity => 4 );
my $chB  = Acme::Parataxis::Channel->new( capacity => 4 );
my $chC1 = Acme::Parataxis::Channel->new( capacity => 4 );
my $chC2 = Acme::Parataxis::Channel->new( capacity => 4 );
my $chD  = Acme::Parataxis::Channel->new( capacity => 4 );
my ( $rA, $rB, $rC, $rD ) = ( 0, 0, 0, 0 );
my $ran = lives {
    async {
        fiber { staged( $chA1, $chA2, \$rA, \$goA, 'A' ) };
        spin( sub {$rA}, 'A to park' );
        fiber { single( $chB, \$rB, 'B' ) };
        spin( sub {$rB}, 'B to park' );
        fiber { staged( $chC1, $chC2, \$rC, \$goC, 'C' ) };
        spin( sub {$rC}, 'C to park' );
        fiber { single( $chD, \$rD, 'D' ) };
        spin( sub {$rD}, 'D to park' );

        # A leaves, then C leaves: CvDEPTH drops below the deepest parked pad.
        $chA1->put('wakeA');
        spin( sub { $left >= 1 }, 'A to leave its first park' );
        $chC1->put('wakeC');
        spin( sub { $left >= 2 }, 'C to leave its first park' );

        # Both re-enter get, C last: this entry used to land on D's parked pad.
        $goA = 1;
        spin( sub { $entered >= 1 }, 'A to re-enter get' );
        $goC = 1;
        spin( sub { $entered >= 2 }, 'C to re-enter get' );

        # C vacates again, then the victim wakes with D's own data waiting.
        $chC2->put('wakeC2');
        spin( sub { exists $REPORT{C} }, 'C to report' );
        $chD->put('wakeD');
        spin( sub { exists $REPORT{D} }, 'D to report' );
        $chB->put('wakeB');
        spin( sub { exists $REPORT{B} }, 'B to report' );
        $chA2->put('wakeA2');
        spin( sub { exists $REPORT{A} }, 'A to report' );
    };
};
ok $ran, 'the choreography ran to completion' or diag $@;
for my $spec ( [ A => 'wakeA2' ], [ B => 'wakeB' ], [ C => 'wakeC2' ], [ D => 'wakeD' ] ) {
    my ( $name, $expect ) = @$spec;
    my $r = $REPORT{$name};
    ok $r, "$name reported back" or next;
    is $r->[0], "lex:$name", "${name}'s lexical survived the parks";
    is $r->[1], $expect,     "$name received its own value";
    is $r->[2], '',          "$name saw no error";
}
is Acme::Parataxis::get_live_fiber_count(), $base, 'and every fiber was reaped';
done_testing;
