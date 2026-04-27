use strict;
use warnings;
use Test::More;
use File::Temp qw(tmpnam);

use Data::HashMap::Shared::II;

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
        my $m = Data::HashMap::Shared::II->new(undef, 64);
        $m->put(1, 1);
    }
    my $after = fd_count();
    ok $after <= $base + 5, "anonymous: no fd leak ($after fds)";
}

{
    my $path = tmpnam() . '.shm';
    for (1..$N) {
        my $m = Data::HashMap::Shared::II->new($path, 64);
    }
    unlink $path;
    my $after = fd_count();
    ok $after <= $base + 5, "file-backed: no fd leak ($after fds)";
}

{
    for (1..$N) {
        my $m = Data::HashMap::Shared::II->new_memfd("t", 64);
    }
    my $after = fd_count();
    ok $after <= $base + 5, "memfd: no fd leak ($after fds)";
}

{
    for (1..$N) {
        my $m = Data::HashMap::Shared::II->new_memfd("t", 64);
        my $fd = $m->memfd;
        my $m2 = Data::HashMap::Shared::II->new_from_fd($fd);
    }
    my $after = fd_count();
    ok $after <= $base + 5, "memfd+new_from_fd: no fd leak ($after fds)";
}

diag "final fd count: " . fd_count();
done_testing;
