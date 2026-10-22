use strict;
use warnings;
use Test::More;
use Data::NDArray::Shared;
use File::Copy qw(copy);
use File::Temp qw(tempdir);
use POSIX qw(_exit WNOHANG);
use Time::HiRes qw(time sleep);

my $dir = tempdir(CLEANUP => 1);
my $path = "$dir/original.nda";
my $clone = "$dir/copy.nda";
my $a = Data::NDArray::Shared->new($path, 'i32', 2)->fill(3);
copy($path, $clone) or die "copy: $!";
my $b = Data::NDArray::Shared->new($clone, 'i32', 2)->fill(5);

for my $case ([ add => 8 ], [ subtract => -2 ], [ multiply => 15 ]) {
    my ($op, $want) = @$case;
    $a->fill(3)->$op($b);
    is_deeply $a->to_list, [ ($want) x 2 ], "$op reads the independent copied file";
    is_deeply $b->to_list, [ 5, 5 ], "$op leaves the copied operand unchanged";
}

link($path, "$dir/link.nda") or die "link: $!";
my $alias = Data::NDArray::Shared->new("$dir/link.nda", 'i32', 2);
$a->fill(3)->add($alias);
is_deeply $a->to_list, [ 6, 6 ], 'a hard link is the same underlying array';
open my $fh, '+<', $path or die "open: $!";
my $fd_alias = Data::NDArray::Shared->new_from_fd(fileno $fh);
$a->multiply($fd_alias);
is_deeply $a->to_list, [ 36, 36 ], 'an fd reopen is the same underlying array';
close $fh;

my $mem = Data::NDArray::Shared->new_memfd(undef, 'i32', 2)->fill(3);
my $mem_alias = Data::NDArray::Shared->new_from_fd($mem->memfd);
$mem->subtract($mem_alias);
is_deeply $mem->to_list, [ 0, 0 ], 'a memfd reopen is the same underlying array';

for my $reverse (0, 1) {
    my $source = Data::NDArray::Shared->new_memfd(undef, 'i32', 2)->fill(3);
    my $path = "$dir/mem-copy$reverse.nda";
    copy('/proc/' . $$ . '/fd/' . $source->memfd, $path) or die "copy: $!";
    my $copied = Data::NDArray::Shared->new($path, 'i32', 2)->fill(5);
    my ($x, $y) = $reverse ? ($copied, $source) : ($source, $copied);
    $x->add($y);
    is_deeply $x->to_list, [ 8, 8 ], "a file copied from a memfd is independent (reverse=$reverse)";
    is_deeply $y->to_list, [ ($reverse ? 3 : 5) x 2 ], 'the copied operand stays unchanged';
}

# Opposing operations must agree on lock order, including copied array IDs.
for my $copied (0, 1) {
    my $p = "$dir/left$copied.nda";
    my $q = "$dir/right$copied.nda";
    my $left = Data::NDArray::Shared->new($p, 'u32', 1);
    copy($p, $q) or die "copy: $!" if $copied;
    my $right = Data::NDArray::Shared->new($q, 'u32', 1);
    pipe(my $start_r, my $start_w) or die "pipe: $!";
    my @pids;
    for my $paths ([ $p, $q ], [ $q, $p ]) {
        my $pid = fork // die "fork: $!";
        if (!$pid) {
            close $start_w;
            my $x = Data::NDArray::Shared->new($paths->[0], 'u32', 1);
            my $y = Data::NDArray::Shared->new($paths->[1], 'u32', 1);
            sysread($start_r, my $ready, 1) == 1 or _exit(2);
            $x->add($y) for 1 .. 1000;
            _exit(0);
        }
        push @pids, $pid;
    }
    close $start_r;
    syswrite($start_w, 'xx') == 2 or die "start: $!";
    close $start_w;
    my $deadline = time + 15;
    my %status;
    while (@pids && time < $deadline) {
        @pids = grep {
            my $done = waitpid($_, WNOHANG);
            $status{$_} = $? if $done == $_;
            $done == 0;
        } @pids;
        sleep 0.01 if @pids;
    }
    my $timed_out = @pids;
    if (@pids) { kill 'KILL', @pids; waitpid($_, 0) for @pids; }
    ok !$timed_out && keys(%status) == 2 && (grep { $_ != 0 } values %status) == 0,
        "opposing add operations complete without deadlock (copied=$copied)";
    is $left->get_flat(0) + $right->get_flat(0), 0, 'both arrays retain their expected values';
}

done_testing;
