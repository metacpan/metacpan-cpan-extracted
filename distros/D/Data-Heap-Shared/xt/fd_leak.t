use strict;
use warnings;
use Test::More;
use File::Temp qw(tmpnam);
use Data::Heap::Shared;

plan skip_all => 'Linux /proc required' unless -d '/proc/self/fd';

sub fd_count {
    opendir my $dh, "/proc/$$/fd" or die;
    my @fds = grep { /^\d+$/ } readdir $dh;
    closedir $dh; scalar @fds;
}

my $base = fd_count();

for (1..200) {
    my $p = tmpnam() . '.shm';
    my $h = Data::Heap::Shared->new($p, 5);
    $h->push(1, 1); $h->pop;
    undef $h; unlink $p;
}
ok fd_count() <= $base + 3, "file-backed: no fd leak";

for (1..200) {
    my $h = Data::Heap::Shared->new_memfd("leak", 5);
    $h->push(1, 1); $h->pop;
}
ok fd_count() <= $base + 3, "memfd: no fd leak";

done_testing;
