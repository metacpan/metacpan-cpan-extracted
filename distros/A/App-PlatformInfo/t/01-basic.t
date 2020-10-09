#!perl

# basically we just want to collect output of platform-info scripts on various
# testing machines

use strict;
use warnings;
use FindBin '$Bin';
use Test::More;

use IPC::Open2;

my $pid = open2 my $chld_out, my $child_in, $^X, "$Bin/../script/platform-info";
my $output = do { local $/; scalar <$chld_out> };
waitpid $pid, 0;
my $child_exit = $? >> 8;

diag "Output of platform-info (exit code $child_exit): ", $output;

ok 1;

done_testing;
