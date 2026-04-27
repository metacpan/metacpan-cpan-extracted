use strict;
use warnings;
use Test::More;
use POSIX qw(_exit);

use Data::Log::Shared;

my $l = Data::Log::Shared->new_memfd("mp", 4096);

my $pid = fork // die;
if (!$pid) {
    my $l2 = Data::Log::Shared->new_from_fd($l->memfd);
    $l2->append("child-entry-$_") for 1..10;
    _exit(0);
}
waitpid $pid, 0;

is $l->entry_count, 10, "child appended 10";

my @entries;
$l->each_entry(sub { push @entries, $_[0] });
is_deeply \@entries, [map "child-entry-$_", 1..10], "log readable after child";

# Parent appends; child-appended + parent-appended visible
$l->append("parent-$_") for 1..3;
is $l->entry_count, 13, "mixed producer count";

done_testing;
