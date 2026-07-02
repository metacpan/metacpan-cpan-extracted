use strict;
use warnings;
use Test::More;
use File::Temp qw(tmpnam);
use Data::SortedSet::Shared;

plan skip_all => 'author test' unless $ENV{AUTHOR_TESTING};
plan skip_all => 'Linux /proc required' unless -d '/proc/self/fd';

sub fd_count {
    opendir my $dh, "/proc/$$/fd" or die "opendir: $!";
    my @fds = grep { /^\d+$/ } readdir $dh;
    closedir $dh;
    scalar @fds;
}

my $base = fd_count();

# file-backed: each open holds a backing fd that DESTROY must close
for (1 .. 200) {
    my $p = tmpnam() . '.shm';
    my $z = Data::SortedSet::Shared->new($p, 100);
    $z->add($_, rand());
    undef $z;
    unlink $p;
}
cmp_ok fd_count(), '<=', $base + 3, 'file-backed: no fd leak across 200 open/close';

# memfd + eventfd: both must be reclaimed on DESTROY
for (1 .. 200) {
    my $z = Data::SortedSet::Shared->new_memfd('leak', 100);
    $z->eventfd;
    $z->add($_, rand());
    undef $z;
}
cmp_ok fd_count(), '<=', $base + 3, 'memfd + eventfd: no fd leak across 200 open/close';

done_testing;
