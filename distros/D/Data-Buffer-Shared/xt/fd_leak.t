use strict;
use warnings;
use Test::More;
use File::Temp qw(tmpnam);

use Data::Buffer::Shared::I64;

sub fd_count {
    opendir my $dh, "/proc/$$/fd" or die "opendir: $!";
    my @fds = grep { /^\d+$/ } readdir $dh;
    closedir $dh;
    scalar @fds;
}

plan skip_all => 'requires /proc/self/fd' unless -d "/proc/$$/fd";

my $N = 2000;
my $base = fd_count();
diag "baseline fd count: $base";

{
    for (1..$N) {
        my $b = Data::Buffer::Shared::I64->new_anon(64);
        $b->set(0, 42);
    }
    my $after = fd_count();
    ok $after <= $base + 5, "anonymous: no fd leak ($after fds)";
}

{
    my $path = tmpnam() . '.shm';
    for (1..$N) {
        my $b = Data::Buffer::Shared::I64->new($path, 64);
    }
    unlink $path;
    my $after = fd_count();
    ok $after <= $base + 5, "file-backed: no fd leak ($after fds)";
}

{
    for (1..$N) {
        my $b = Data::Buffer::Shared::I64->new_memfd("t", 64);
    }
    my $after = fd_count();
    ok $after <= $base + 5, "memfd: no fd leak ($after fds)";
}

{
    for (1..$N) {
        my $b = Data::Buffer::Shared::I64->new_memfd("t", 64);
        my $fd = $b->memfd;
        my $b2 = Data::Buffer::Shared::I64->new_from_fd($fd);
    }
    my $after = fd_count();
    ok $after <= $base + 5, "memfd+new_from_fd: no fd leak ($after fds)";
}

{
    for (1..$N) {
        eval { Data::Buffer::Shared::I64->new_from_fd(9999) };
    }
    my $after = fd_count();
    ok $after <= $base + 5, "error path: no fd leak ($after fds)";
}

diag "final fd count: " . fd_count();
done_testing;
