use strict;
use warnings;
use Test::More;
use File::Temp qw(tmpnam);
use Data::Pool::Shared;

plan skip_all => 'Linux /proc required' unless -d '/proc/self/fd';

sub fd_count {
    opendir my $dh, "/proc/$$/fd" or die "opendir: $!";
    my @fds = grep { /^\d+$/ } readdir $dh;
    closedir $dh;
    scalar @fds;
}

my $base = fd_count();
diag "baseline fd count: $base";

# file-backed create/destroy cycles
for (1..200) {
    my $path = tmpnam() . '.shm';
    my $pool = Data::Pool::Shared::I64->new($path, 10);
    my $s = $pool->alloc;
    $pool->set($s, $_);
    $pool->free($s);
    undef $pool;
    unlink $path;
}

my $after_file = fd_count();
ok $after_file <= $base + 3, "file-backed: no fd leak ($base -> $after_file)";

# memfd create/destroy cycles
for (1..200) {
    my $pool = Data::Pool::Shared::I64->new_memfd("leak_test", 10);
    my $s = $pool->alloc;
    $pool->set($s, $_);
    $pool->free($s);
}

my $after_memfd = fd_count();
ok $after_memfd <= $base + 3, "memfd: no fd leak ($base -> $after_memfd)";

# eventfd create/destroy cycles
for (1..200) {
    my $pool = Data::Pool::Shared::I64->new(undef, 5);
    my $efd = $pool->eventfd;
    $pool->notify;
    $pool->eventfd_consume;
}

my $after_efd = fd_count();
ok $after_efd <= $base + 3, "eventfd: no fd leak ($base -> $after_efd)";

# new_from_fd cycles
my $src = Data::Pool::Shared::I64->new_memfd("fd_src", 10);
my $src_fd = $src->memfd;
for (1..200) {
    my $dup = Data::Pool::Shared::I64->new_from_fd($src_fd);
    my $s = $dup->alloc;
    $dup->set($s, $_);
    $dup->free($s);
}

my $after_dup = fd_count();
ok $after_dup <= $base + 5, "new_from_fd: no fd leak ($base -> $after_dup)";

done_testing;
