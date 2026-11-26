use strict;
use warnings;
use Test::More;
use Cwd qw(abs_path);
use File::Basename qw(dirname);
use File::Temp qw(tempdir);
use Fcntl qw(O_RDWR);
use POSIX qw(_exit);
use Time::HiRes qw(time);

# From another PID namespace the lock holder's PID is not visible, so it must not be taken for dead.

plan skip_all => 'Linux only' unless $^O eq 'linux';
-e '/proc/self/ns/pid' or plan skip_all => 'needs /proc/self/ns/pid';
system('unshare -Urpf true >/dev/null 2>&1') == 0
    or plan skip_all => 'needs an unprivileged user and PID namespace';

my $root = dirname(dirname(abs_path(__FILE__)));
require Data::Queue::Shared::Str;
my $dir = tempdir(CLEANUP => 1);
my $path = "$dir/q.shm";
my $q = Data::Queue::Shared::Str->new($path, 64, 1 << 16);

sub hold_as {    # QueueHeader.mutex is at offset 192
    my ($pid) = @_;
    sysopen my $fh, $path, O_RDWR or die "$path: $!";
    sysseek $fh, 192, 0 or die $!;
    syswrite($fh, pack('L', $pid ? 0x80000000 | $pid : 0)) == 4 or die $!;
}

open my $fh, '>', "$dir/child.pl" or die $!;
print {$fh} <<'P';
use strict; use warnings;
use Data::Queue::Shared::Str;
my $q = Data::Queue::Shared::Str->new($ARGV[0], 64, 1 << 16);
$q->lock_timeout(0.3);
print $q->push('x') ? 'pushed' : "refused: $!", "; recoveries ", $q->stats->{recoveries}, "\n";
P
close $fh;

hold_as($$);
my $out = qx{unshare -Urpf $^X -I$root/blib/lib -I$root/blib/arch $dir/child.pl $path 2>&1};
like $out, qr/^refused: Resource temporarily unavailable; recoveries 0$/,
    'a live holder in another PID namespace keeps the lock';

hold_as(0);
my $dead = fork // die "fork: $!";
_exit(0) unless $dead;
waitpid $dead, 0;
hold_as($dead);
my $t0 = time;
ok $q->push('y'), 'a dead holder is still taken over';
cmp_ok time - $t0, '>=', 1.5, '  but only after 2 s once another PID namespace has attached';

done_testing;
