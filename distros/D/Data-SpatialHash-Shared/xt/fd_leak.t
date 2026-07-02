use strict;
use warnings;
use Test::More;
use File::Temp qw(tmpnam);
use Data::SpatialHash::Shared;

plan skip_all => 'author test' unless $ENV{AUTHOR_TESTING};
plan skip_all => 'Linux /proc required' unless -d '/proc/self/fd';

sub fd_count {
    opendir my $dh, "/proc/$$/fd" or die;
    my @fds = grep { /^\d+$/ } readdir $dh;
    closedir $dh; scalar @fds;
}

my $base = fd_count();

for (1..200) {
    my $p = tmpnam() . '.shm';
    my $s = Data::SpatialHash::Shared->new($p, 100, 0, 1.0);
    $s->insert(rand()*10, rand()*10, $_);
    undef $s; unlink $p;
}
ok fd_count() <= $base + 3, "file-backed: no fd leak";

done_testing;
