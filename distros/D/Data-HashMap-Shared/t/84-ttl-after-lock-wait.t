use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use POSIX ();
use Data::HashMap::Shared::II;

# A call that waits for the lock judges expiry when it gets it, not when it
# asked. A live process named in the lock word holds every caller until it is
# killed.

plan skip_all => 'Linux only' unless $^O eq 'linux';
my $dir = tempdir(CLEANUP => 1);
my $p = "$dir/w.shm";
my $m = Data::HashMap::Shared::II->new($p, 64, 0, 60);
$m->put_ttl($_, $_, 1) for 1 .. 11;

my $holder = fork // die "fork: $!";
if (!$holder) { exec('sleep', '30') or POSIX::_exit(1) }
open my $fh, '+<', $p or die $!;
sysseek($fh, 128, 0);
syswrite($fh, pack('L', 0x80000000 | $holder));
close $fh;

my %op = (
    add     => sub { $_[0]->add(1, 10) ? 'stored' : 'refused' },
    touch   => sub { $_[0]->touch(2) ? 'touched' : 'absent' },
    persist => sub { $_[0]->persist(3) ? 'kept' : 'absent' },
    incr    => sub { $_[0]->incr(4) },
    cas     => sub { $_[0]->cas(5, 5, 50) ? 'swapped' : 'absent' },
    get_with_ttl => sub { my @r = $_[0]->get_with_ttl(6); @r ? 'hit' : 'absent' },
    get_multi    => sub { my @r = $_[0]->get_multi(7, 7); defined $r[0] ? 'hit' : 'absent' },
    keys    => sub { (grep { $_ == 8 } $_[0]->keys) ? 'listed' : 'absent' },
    update  => sub { $_[0]->update(9, 90) ? 'updated' : 'absent' },
    swap    => sub { defined $_[0]->swap(10, 100) ? 'old value' : 'none' },
    take    => sub { defined $_[0]->take(11) ? 'taken' : 'absent' },
);
my %want = (add => 'stored', touch => 'absent', persist => 'absent', incr => 1, cas => 'absent',
            get_with_ttl => 'absent', get_multi => 'absent', keys => 'absent',
            update => 'absent', swap => 'none', take => 'absent');
my %pipe;
for my $name (sort keys %op) {
    pipe(my $r, my $w) or die $!;
    my $pid = fork // die "fork: $!";
    if (!$pid) {
        close $r;
        alarm 20;
        my $h = Data::HashMap::Shared::II->new($p, 64, 0, 60);
        syswrite $w, $op{$name}->($h);
        POSIX::_exit(0);
    }
    close $w;
    $pipe{$name} = [$r, $pid];
}
sleep 2;                 # the callers wait, and their keys expire meanwhile
kill 'KILL', $holder;
waitpid $holder, 0;
for my $name (sort keys %op) {
    my ($r, $pid) = @{ $pipe{$name} };
    my $got = do { local $/; <$r> };
    waitpid $pid, 0;
    is $got, $want{$name}, "$name after the wait sees its key expired";
}

done_testing;
