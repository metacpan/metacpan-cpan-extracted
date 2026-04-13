use strict;
use warnings;
use Test::More;
use File::Temp qw(tmpnam);
use Data::Log::Shared;

plan skip_all => 'Linux /proc required' unless -d '/proc/self/fd';

sub fd_count {
    opendir my $dh, "/proc/$$/fd" or die;
    my @fds = grep { /^\d+$/ } readdir $dh;
    closedir $dh;
    scalar @fds;
}

my $base = fd_count();

for (1..200) {
    my $path = tmpnam() . '.shm';
    my $l = Data::Log::Shared->new($path, 1024);
    $l->append("test"); undef $l;
    unlink $path;
}
ok fd_count() <= $base + 3, "file-backed: no fd leak";

for (1..200) {
    my $l = Data::Log::Shared->new_memfd("leak", 1024);
    $l->append("test");
}
ok fd_count() <= $base + 3, "memfd: no fd leak";

for (1..200) {
    my $l = Data::Log::Shared->new(undef, 1024);
    $l->eventfd; $l->notify; $l->eventfd_consume;
}
ok fd_count() <= $base + 3, "eventfd: no fd leak";

done_testing;
