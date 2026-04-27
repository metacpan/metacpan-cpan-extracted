use strict;
use warnings;
use Test::More;
use File::Temp qw(tmpnam);

use Data::Queue::Shared::Int;

sub fd_count {
    opendir my $dh, "/proc/$$/fd" or die "opendir: $!";
    my @fds = grep { /^\d+$/ } readdir $dh;
    closedir $dh;
    scalar @fds;
}

plan skip_all => 'requires /proc/self/fd' unless -d "/proc/$$/fd";

my $N = 1000;
my $base = fd_count();
diag "baseline fd count: $base";

{
    for (1..$N) {
        my $q = Data::Queue::Shared::Int->new(undef, 16);
        $q->push($_);
        $q->pop;
    }
    my $after = fd_count();
    ok $after <= $base + 5, "anonymous: no fd leak ($after fds)";
}

{
    my $path = tmpnam() . '.shm';
    for (1..$N) {
        my $q = Data::Queue::Shared::Int->new($path, 16);
    }
    unlink $path;
    my $after = fd_count();
    ok $after <= $base + 5, "file-backed: no fd leak ($after fds)";
}

{
    for (1..$N) {
        my $q = Data::Queue::Shared::Int->new_memfd("t", 16);
    }
    my $after = fd_count();
    ok $after <= $base + 5, "memfd: no fd leak ($after fds)";
}

diag "final fd count: " . fd_count();
done_testing;
