use strict;
use warnings;
use Test::More;
use File::Temp qw(tmpnam);
use Data::Graph::Shared;

plan skip_all => 'Linux /proc required' unless -d '/proc/self/fd';

sub fd_count {
    opendir my $dh, "/proc/$$/fd" or die;
    my @fds = grep { /^\d+$/ } readdir $dh;
    closedir $dh; scalar @fds;
}

my $base = fd_count();

for (1..200) {
    my $p = tmpnam() . '.shm';
    my $g = Data::Graph::Shared->new($p, 5, 10);
    my $n = $g->add_node(1);
    $g->remove_node($n);
    undef $g; unlink $p;
}
ok fd_count() <= $base + 3, "file-backed: no fd leak";

done_testing;
