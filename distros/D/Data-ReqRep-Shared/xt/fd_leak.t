use strict;
use warnings;
use Test::More;
use File::Temp qw(tmpnam);

use Data::ReqRep::Shared;

sub fd_count {
    opendir my $dh, "/proc/$$/fd" or die "opendir: $!";
    my @fds = grep { /^\d+$/ } readdir $dh;
    closedir $dh;
    scalar @fds;
}

plan skip_all => 'requires /proc/self/fd' unless -d "/proc/$$/fd";

my $N = 500;
my $base = fd_count();
diag "baseline fd count: $base";

{
    for (1..$N) {
        my $s = Data::ReqRep::Shared->new(undef, 8, 4, 128);
    }
    my $after = fd_count();
    ok $after <= $base + 5, "anonymous: no fd leak ($after fds)";
}

{
    my $path = tmpnam() . '.shm';
    for (1..$N) {
        my $s = Data::ReqRep::Shared->new($path, 8, 4, 128);
    }
    unlink $path;
    my $after = fd_count();
    ok $after <= $base + 5, "file-backed: no fd leak ($after fds)";
}

{
    for (1..$N) {
        my $s = Data::ReqRep::Shared->new_memfd("t", 8, 4, 128);
    }
    my $after = fd_count();
    ok $after <= $base + 5, "memfd: no fd leak ($after fds)";
}

diag "final fd count: " . fd_count();
done_testing;
