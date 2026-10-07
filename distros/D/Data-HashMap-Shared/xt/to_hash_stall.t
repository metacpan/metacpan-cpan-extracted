use strict;
use warnings;
use Test::More;
use Time::HiRes qw(time sleep);
use POSIX ();
use File::Temp qw(tempdir);

plan skip_all => 'author tests' unless $ENV{AUTHOR_TESTING};
my $load = do {
    if (open my $f, '<', '/proc/loadavg') { (split ' ', <$f>)[0] } else { undef }
};
plan skip_all => 'no /proc/loadavg, so a timing ratio cannot be qualified' unless defined $load;
plan skip_all => "machine too loaded for a timing ratio (loadavg $load)" if $load > 4;

use Data::HashMap::Shared::II;

# to_hash copies the entries under the read lock and builds the hash once it is
# released, so a writer waits for the copy, not for the hash inserts.  Priced
# against the call itself, so the ratio holds on any machine.

my $dir = tempdir(CLEANUP => 1);
my $n = 500_000;
my $m = Data::HashMap::Shared::II->new("$dir/stall.shm", $n);
for (my $b = 1; $b <= $n; $b += 100_000) { $m->set_multi(map { ($_, $_) } $b .. $b + 99_999) }

pipe my $r, my $w or die "pipe: $!";
my $pid = fork // die "fork: $!";
unless ($pid) {
    close $r;
    my $c = Data::HashMap::Shared::II->new("$dir/stall.shm", $n);
    my ($worst, $end) = (0, time + 3);
    while ((my $t = time) < $end) {
        $c->put(1 + int rand $n, 7);
        my $d = time - $t;
        $worst = $d if $d > $worst;
    }
    print $w "$worst\n"; close $w;
    POSIX::_exit(0);
}
close $w;
sleep 0.3;
my $call = 0;
for (1 .. 5) {
    my $t = time;
    my $h = $m->to_hash;
    my $d = time - $t;
    $call = $d if $d > $call;
    undef $h;
    sleep 0.1;
}
chomp(my $worst = <$r>);
waitpid $pid, 0;
cmp_ok $worst, '<', $call / 3,
    sprintf('a writer waits at most %.0f ms while to_hash takes up to %.0f ms', $worst * 1e3, $call * 1e3);

done_testing;
