use strict;
use warnings;
use Test::More;
use Cwd qw(abs_path);
use File::Basename qw(dirname);
use File::Temp qw(tempdir);

# Without /proc a process keeps retrying to register; that retry must not ride on every call.

plan skip_all => 'Linux only' unless $^O eq 'linux';
system(q{unshare -Urm sh -c 'mount -t tmpfs none /proc' >/dev/null 2>&1}) == 0
    or plan skip_all => 'needs unshare -Urm (unprivileged user and mount namespaces)';

my $root = dirname(dirname(abs_path(__FILE__)));
my $dir  = tempdir(CLEANUP => 1);
open my $fh, '>', "$dir/trips.pl" or die $!;
print {$fh} <<'P';
use strict; use warnings;
use Time::HiRes qw(time);
use Data::ReqRep::Shared; use Data::ReqRep::Shared::Client;
my $s = Data::ReqRep::Shared->new(undef, 64, 64, 64);
my $c = Data::ReqRep::Shared::Client->new_from_fd($s->memfd);
my $n = 30000;
my $t0 = time;
for (1 .. $n) { my $id = $c->send('x'); my (undef, $rid) = $s->recv; $s->reply($rid, 'y'); $c->get($id) }
printf "%.0f\n", $n / (time - $t0);
P
close $fh;

sub rate {
    my ($hide) = @_;
    my $mount = $hide ? 'mount -t tmpfs none /proc && ' : '';
    my @best;
    for (1 .. 3) {
        my $out = qx{unshare -Urm sh -c '${mount}DATA_REQREP_SHARED_UNSAFE_PIDNS=1 exec "\$@"' sh $^X -I$root/blib/lib -I$root/blib/arch $dir/trips.pl 2>&1};
        $out =~ /^(\d+)$/m or return diag("no rate: $out");
        push @best, $1;
    }
    my ($max) = sort { $b <=> $a } @best;
    return $max;
}

my $with    = rate(0);
my $without = rate(1);
ok $with && $without, 'round trips run with and without /proc';
SKIP: {
    skip 'no rate to compare', 1 unless $with && $without;
    diag sprintf 'round trips per second: %d with /proc, %d without', $with, $without;
    cmp_ok $without / $with, '>', 0.3, 'a process without /proc makes round trips about as fast';
}

done_testing;
