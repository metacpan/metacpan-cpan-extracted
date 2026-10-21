use strict;
use warnings;
use Test::More;
use IO::Select;
use POSIX qw(_exit);
use Time::HiRes qw(time);

use Data::Buffer::Shared::I64;

plan skip_all => 'requires /proc process states' unless -r '/proc/self/stat';

# Keep the killed writer unreaped: kill(pid, 0) still succeeds for a zombie.
for my $op (qw(slice get_raw fill lock_rd)) {
    my $b = Data::Buffer::Shared::I64->new_anon(2);
    pipe(my $ready_r, my $ready_w) or die "pipe: $!";
    pipe(my $hold_r, my $hold_w) or die "pipe: $!";
    my $writer = fork // die "fork: $!";
    unless ($writer) {
        close $ready_r;
        close $hold_w;
        $b->lock_wr;
        $b->set(0, 111);
        syswrite($ready_w, '1');
        sysread($hold_r, my $release, 1);
        _exit(0);
    }
    close $ready_w;
    close $hold_r;
    sysread($ready_r, my $ready, 1) == 1 or die 'writer did not start';
    kill 'KILL', $writer;
    my $deadline = time + 3;
    my $zombie;
    while (time < $deadline) {
        open my $stat, '<', "/proc/$writer/stat" or last;
        my $state = <$stat>;
        $zombie = $state =~ /\) Z /;
        last if $zombie;
        select undef, undef, undef, 0.01;
    }
    ok($zombie, "$op writer is dead but unreaped");

    pipe(my $done_r, my $done_w) or die "pipe: $!";
    my $contender = fork // die "fork: $!";
    unless ($contender) {
        close $done_r;
        my $ok = eval {
            if ($op eq 'slice') { my @v = $b->slice(0, 1); die unless $v[0] == 111 }
            elsif ($op eq 'get_raw') { die unless unpack('q<', $b->get_raw(0, 8)) == 111 }
            elsif ($op eq 'fill') { $b->fill(222); die unless $b->get(0) == 222 }
            else { $b->lock_rd; $b->unlock_rd }
            1;
        };
        syswrite($done_w, $ok ? '1' : '0');
        _exit($ok ? 0 : 1);
    }
    close $done_w;
    my $finished = IO::Select->new($done_r)->can_read(5);
    my $result = '';
    sysread($done_r, $result, 1) if $finished;
    kill 'KILL', $contender unless $finished;
    waitpid($contender, 0);
    ok($finished && $result eq '1' && $? == 0, "$op recovers the writer lock and odd seqlock");
    cmp_ok($b->stats->{recoveries}, '>=', 1, "$op records the recovery");
    waitpid($writer, 0);
}
done_testing;
