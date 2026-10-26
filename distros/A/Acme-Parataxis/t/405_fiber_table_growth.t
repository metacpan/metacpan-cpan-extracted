use v5.40;
no warnings 'recursion';    # fibers run on separate heap stacks; Perl's C-stack-depth heuristic misfires there
use blib;
use Acme::Parataxis qw[async fiber dump_fibers];
use Acme::Parataxis::Signal;
use Test2::V1 -ipP;
$|++;

# Fibers run on separate heap stacks; Perl's C-stack-depth heuristic can misfire and falsely report "Deep recursion"
# (it ignores lexical 'no warnings' once a framework such as Test2 is loaded). Genuine runaway recursion inside a fiber
# surfaces as a hang, access violation, or croak the harness already catches, so filter the noise.
BEGIN {
    $SIG{__WARN__} = sub { return if $_[0] =~ /^Deep recursion on subroutine/; warn @_ }
}

# The fiber table used to be a fixed MAX_FIBERS array compiled into Parataxis.c, so the 1025th fiber croaked "the fiber
# table is full" no matter how much memory was free. It is now allocated on demand (doubling, bounded) and split into
# two independent things: the allocated table, which grows silently, and the limit on how many fibers may exist, which
# is policy set_max_fibers() may raise or lower at any moment because it is enforced against the slots in use rather
# than against the array.
my $BASE = Acme::Parataxis::get_live_fiber_count();
sub live () { Acme::Parataxis::get_live_fiber_count() }

# Spawn up to $n fibers parked on a shared signal, stopping at the first croak. Returns the count made and that error.
sub spawn_parked ( $n, $sig ) {
    my ( $made, $err ) = ( 0, undef );
    for ( 1 .. $n ) {
        my $died = dies {
            fiber { $sig->wait };
        };
        if ($died) { $err = $died; last }
        $made++;
    }
    return ( $made, $err );
}

# Release everything parked on $sig and let it unwind before the next scenario starts.
sub drain ( $sig, $here ) {
    $sig->broadcast;
    Acme::Parataxis->yield while live() > $here;
}
my ( $default, $want1, $target2, $r1, $r2, $r3, $r4, $r5, $reaches1024 );
async {
    my $here = live();    # this run's fiber, which exists for the whole block below

    # On platforms without MAP_NORESERVE (OpenBSD) the library clamps the default limit to the number of 8 MiB
    # stacks RLIMIT_DATA can host, so the old 1100/1300 targets are replaced by the achievable default minus two
    # (the policy, not the stack mmap, must be what refuses the next spawn). Both bursts below are sized from it.
    $default = Acme::Parataxis::max_fibers();

    # 1) The diagnostics snapshot has to keep up with the growth. dump_fibers() walks the slots itself, and it used to
    #    walk a hardcoded first 1024 of them, so every fiber past that - exactly the ones a full table is made of, and
    #    exactly the ones a deadlock report has to name - went missing. Run first, while the table is still at its
    #    initial 1024 and this fiber holds slot 0, so the ids in play are guaranteed to straddle 1024 rather than
    #    depending on which slots later scenarios happen to recycle.
    #
    #    That needs more than 1024 fibers to exist at once, which is exactly what the MAP_NORESERVE clamp on
    #    OpenBSD forbids: there the default is a few hundred, so the premise is unreachable and asking for 1100 only
    #    re-proved that the limit is enforced (scenario 2 already checks that). Ask for the same achievable target
    #    instead, and let $reaches1024 decide what the snapshot subtest is allowed to claim.
    $reaches1024 = $default > 1024;
    my $sig5 = Acme::Parataxis::Signal->new;
    my ( $made5, $err5 ) = spawn_parked( $reaches1024 ? 1100 : $default - 2, $sig5 );
    my $rows5 = Acme::Parataxis::dump_fibers();
    $r5 = [ $made5, $err5, scalar @$rows5, scalar( grep { $_->{fid} >= 1024 } @$rows5 ) ];
    drain( $sig5, $here );

    # 2) With nobody configuring anything, the default must already be reachable in one burst.
    $want1 = $default > 1024 ? 1100 : $default - 2;
    my $sig1 = Acme::Parataxis::Signal->new;
    my ( $made1, $err1 ) = spawn_parked( $want1, $sig1 );
    $r1 = [ $made1, $err1, live() ];
    drain( $sig1, $here );

    # 3) A limit the user sets is enforced exactly and read back exactly.
    $target2 = $default > 1024 ? 1300 : $default - 2;
    Acme::Parataxis::set_max_fibers($target2);
    my $sig2 = Acme::Parataxis::Signal->new;
    my ( $made2, $err2 ) = spawn_parked( 5000, $sig2 );    # keeps going until it croaks
    $r2 = [ $made2, $err2, live(), Acme::Parataxis::max_fibers() ];
    drain( $sig2, $here );

    # 4) Lowering the limit is honoured too, even though the table is already allocated far below it.
    Acme::Parataxis::set_max_fibers(40);
    my $sig3 = Acme::Parataxis::Signal->new;
    my ( $made3, $err3 ) = spawn_parked( 5000, $sig3 );
    $r3 = [ $made3, $err3, live(), Acme::Parataxis::max_fibers() ];
    drain( $sig3, $here );

    # 5) And raising it again frees the way with no reallocation and no restart.
    Acme::Parataxis::set_max_fibers(5000);
    my $sig4 = Acme::Parataxis::Signal->new;
    my ( $made4, $err4 ) = spawn_parked( 50, $sig4 );
    $r4 = [ $made4, $err4 ];
    drain( $sig4, $here );
};
subtest 'the diagnostics snapshot reaches fibers past the old fixed 1024 slots' => sub {
    my $want = $reaches1024 ? 1100 : $default - 2;
    is $r5->[0], $want,
        $reaches1024 ? 'spawned 1100 fibers unconfigured, past the 1024 the snapshot used to stop at' :
        sprintf( 'the default only reaches %d, so the past-1024 case is unbuildable; took all %d', $default, $want );
    ok !defined $r5->[1], 'and not one of them croaked' or diag "err: $r5->[1]";
    if ($reaches1024) {
        cmp_ok $r5->[3], '>', 0, sprintf 'the dump listed %d live fiber(s) with an id of 1024 or more', $r5->[3];
    }
    else {
        is $r5->[3], 0, 'nothing can be past 1024 when the clamp caps the table below it';
    }
    cmp_ok $r5->[2], '>=', $r5->[0], sprintf 'and listed every live fiber, none silently dropped (%d rows)', $r5->[2];
};
subtest 'the default limit is reachable without configuring anything' => sub {
    if ( $default > 1024 ) {
        cmp_ok $default, '>', 1024, sprintf 'default fiber limit is %d, beyond the 1024 the table used to be compiled to', $default;
        is $r1->[0], 1100, 'spawned 1100 fibers unconfigured, where the fixed table croaked at 1024';
    }
    else {
        note "platform without MAP_NORESERVE clamps the default to $default (RLIMIT_DATA / FIBER_STACK_SZ)";
        cmp_ok $default, '>', 8, 'the clamp still leaves a usable default limit';
        is $r1->[0], $default - 2, sprintf 'spawned to the clamped default without croaking (%d)', $r1->[0];
    }
    ok !defined $r1->[1], 'and not one of them croaked' or diag "err: $r1->[1]";
    cmp_ok $r1->[2], '>=', $r1->[0], sprintf 'control: all of them were live at once (%d)', $r1->[2];
};
subtest 'set_max_fibers caps the table exactly, and reports back what it was set to' => sub {
    is $r2->[3], $target2, 'max_fibers() reads back the limit that was set';
    is $r2->[2], $target2, 'and exactly the limit fibers existed when spawning stopped';
    is $r2->[0], $target2, sprintf 'spawned exactly that many before the limit refused the next one (%d)', $r2->[0];
    like $r2->[1], qr/fiber table is full/, 'with the documented message';
};
subtest 'the limit is live: lowering it bites immediately, raising it works again' => sub {
    is $r3->[3], 40, 'max_fibers() reads back the lowered limit';
    is $r3->[2], 40, 'and it stopped at 40 even though the table had already been allocated far larger';
    like $r3->[1], qr/fiber table is full/, 'with the same message';
    is $r4->[0], 50,  'raising it again let fibers through with no restart';
    is $r4->[1], U(), 'and none of those croaked';
};
is live(), $BASE, 'every fiber these scenarios created was reaped';
#
done_testing;
