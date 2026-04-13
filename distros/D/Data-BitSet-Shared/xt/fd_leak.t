use strict;
use warnings;
use Test::More;
use File::Temp qw(tmpnam);
use Data::BitSet::Shared;
plan skip_all => 'Linux /proc required' unless -d '/proc/self/fd';
sub fd_count { opendir my $d, "/proc/$$/fd" or die; my @f = grep /^\d+$/, readdir $d; closedir $d; scalar @f }
my $base = fd_count();
for (1..200) { my $p = tmpnam().'.shm'; my $b = Data::BitSet::Shared->new($p, 64); $b->set(0); undef $b; unlink $p }
ok fd_count() <= $base + 3, "file-backed: no fd leak";
for (1..200) { my $b = Data::BitSet::Shared->new_memfd("leak", 64); $b->set(0) }
ok fd_count() <= $base + 3, "memfd: no fd leak";
done_testing;
