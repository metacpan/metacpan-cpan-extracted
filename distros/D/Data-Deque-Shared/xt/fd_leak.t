use strict;
use warnings;
use Test::More;
use File::Temp qw(tmpnam);
use Data::Deque::Shared;

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
    my $d = Data::Deque::Shared::Int->new($path, 5);
    $d->push_back(1); $d->pop_front;
    undef $d;
    unlink $path;
}
ok fd_count() <= $base + 3, "file-backed: no fd leak";

for (1..200) {
    my $d = Data::Deque::Shared::Int->new_memfd("leak", 5);
    $d->push_back(1); $d->pop_front;
}
ok fd_count() <= $base + 3, "memfd: no fd leak";

for (1..200) {
    my $d = Data::Deque::Shared::Int->new(undef, 5);
    $d->eventfd; $d->notify; $d->eventfd_consume;
}
ok fd_count() <= $base + 3, "eventfd: no fd leak";

done_testing;
