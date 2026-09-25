use strict;
use warnings;
use Test::More;
use Fcntl qw(:flock);
use File::Temp qw(tempdir);
use POSIX ();
use Time::HiRes qw(time);
use Data::ReqRep::Shared;
use Data::ReqRep::Shared::Client;

my $path = tempdir(CLEANUP => 1) . '/held.shm';
Data::ReqRep::Shared->new($path, 4, 2, 64);

pipe my $r, my $w or die $!;
my $holder = fork // die $!;
if (!$holder) {
    open my $fh, '<', $path or die $!;
    flock $fh, LOCK_EX or die $!;
    syswrite $w, 'x';
    sleep 60;
    POSIX::_exit(0);
}
close $w;
sysread $r, my $go, 1;

for my $case (['new', sub { Data::ReqRep::Shared->new($path, 4, 2, 64) }],
              ['a client', sub { Data::ReqRep::Shared::Client->new($path) }]) {
    my $t0 = time;
    ok !eval { $case->[1]->(); 1 }, "$case->[0] gives up on a lock another process holds";
    my $took = time - $t0;
    cmp_ok $took, '<', 15, sprintf '  after the documented 10 s (took %.1f s)', $took;
    cmp_ok $took, '>', 8, '  not before it';
}

kill KILL => $holder;
waitpid $holder, 0;

# Signals arriving faster than it waits would pile up until Perl dies of them.
{
    my $q = tempdir(CLEANUP => 1) . '/mutex.shm';
    my $s = Data::ReqRep::Shared->new($q, 16, 4, 64);
    my $c = Data::ReqRep::Shared::Client->new($q);
    my $poke = sub { open my $fh, '+<', $q or die $!; binmode $fh; seek $fh, 192, 0; print {$fh} pack 'L', $_[0]; close $fh };
    $poke->(0x8000_0000 | $$);            # a live process holds the mutex and never lets go
    local $SIG{ALRM} = sub { };
    Time::HiRes::setitimer(Time::HiRes::ITIMER_REAL(), 0.005, 0.005);
    for my $call (['send', sub { $c->send('x') }], ['recv', sub { $s->recv }]) {
        my $t0 = time;
        my $ok = eval { $call->[1]->(); 1 };
        my $err = $@;
        my $took = time - $t0;
        ok $ok, "a non-blocking $call->[0] behind a held mutex under a 200 Hz signal returns" or diag $err;
        cmp_ok $took, '<', 2.5, sprintf '  within its two seconds (%.2f s)', $took;
    }
    Time::HiRes::setitimer(Time::HiRes::ITIMER_REAL(), 0, 0);
    $poke->(0);
    ok defined $c->send('y'), 'the channel works once the mutex is free';
}

done_testing;
