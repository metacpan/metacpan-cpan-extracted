#!/usr/bin/perl

use strict;
use Test::More tests => 1;
use File::Spec;
use lib qw(t/lib);
use MyAppFail;
delete $ENV{APPCLI_NON_EXIT};

my @argv = ("fail");

my $pid;
if ($pid = fork) {
	# parent
	waitpid -1, 0;
	my $exit_value = $? >> 8;
	ok($exit_value == 1);
} elsif (defined $pid) {
	# child
    local *ARGV = \@argv;
    MyAppFail->dispatch;
} else {
	die "can not fork: $!";
}
