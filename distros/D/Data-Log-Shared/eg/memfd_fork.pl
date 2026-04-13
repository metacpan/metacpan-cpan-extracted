#!/usr/bin/env perl
# memfd: create log, child opens via fd, both append and read
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use POSIX qw(_exit);
use Data::Log::Shared;
$| = 1;

my $log = Data::Log::Shared->new_memfd("demo_log", 4096);
my $fd = $log->memfd;
printf "parent: memfd=%d\n", $fd;

$log->append("parent entry 1");
$log->append("parent entry 2");

my $pid = fork // die;
if ($pid == 0) {
    my $child = Data::Log::Shared->new_from_fd($fd);
    printf "child:  sees %d entries\n", $child->entry_count;
    $child->append("child entry 1");
    _exit(0);
}
waitpid($pid, 0);

printf "parent: total %d entries\n", $log->entry_count;
$log->each_entry(sub { printf "  %s\n", $_[0] });
