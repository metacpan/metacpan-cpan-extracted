use strict;
use warnings;
use Test::More;
use IO::Select;
use POSIX qw(_exit);
use Time::HiRes qw(time);

use Data::Buffer::Shared::I64;

my $b = Data::Buffer::Shared::I64->new_anon(64);

my $N = 6;
my $OPS = 10000;
pipe(my $start_r, my $start_w) or die "pipe: $!";

my $t0 = time;
my @pids;
for my $k (0..$N-1) {
    my $pid = fork // die;
    if ($pid == 0) {
        close $start_w;
        sysread($start_r, my $start, 1) == 1 or _exit(2);
        for (1..$OPS) {
            $b->lock_rd;
            my ($first, $last) = ($b->get(0), $b->get(63));
            $b->unlock_rd;
            _exit(1) if $first != $last;
        }
        _exit(0);
    }
    push @pids, $pid;
}

pipe(my $done_r, my $done_w) or die "pipe: $!";
my $writer = fork // die "fork: $!";
unless ($writer) {
    close $done_r;
    close $start_w;
    sysread($start_r, my $start, 1) == 1 or _exit(2);
    $b->fill($_) for 1 .. 500;
    syswrite($done_w, '1');
    _exit(0);
}
close $start_r;
close $done_w;
syswrite($start_w, '1' x ($N + 1)) == $N + 1 or die "start workers: $!";
close $start_w;
my $done = IO::Select->new($done_r)->can_read(10);
unless ($done) { kill 'KILL', $writer, @pids }
waitpid($writer, 0);
ok($done && $? == 0, 'writer advances despite concurrent read locks');

my $fails = 0;
for my $pid (@pids) { waitpid $pid, 0; $fails++ if $? }
my $dt = time - $t0;

is $fails, 0, "$N readers × $OPS locked reads remain coherent";
ok $dt < 10, sprintf('completed in %.2fs', $dt);

done_testing;
