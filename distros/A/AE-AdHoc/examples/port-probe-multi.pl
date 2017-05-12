#!/usr/bin/perl -w

use strict;
use AE::AdHoc;
use AnyEvent::Socket;
use Getopt::Long;

my $timeout = 1;

GetOptions (
	"timeout=s" => \$timeout,
	"help" => \&usage,
) or usage();

my @probe = map {
	/^(.*):(\d+)$/ or die "Expecting host:port. See $0 --help\n"; [$1, $2, $_];
} @ARGV;
usage() unless @probe;

# Real work
eval {
	ae_recv {
		tcp_connect $_->[0], $_->[1], ae_goal("$_->[0]:$_->[1]") for @probe;
	} $timeout;
};
die $@ if $@ and $@ !~ /^Timeout/;

my @offline = sort keys %{ AE::AdHoc->goals };
my (@alive, @reject);

my $results = AE::AdHoc->results;
foreach (keys %$results) {
	# tcp_connect will not feed any args if connect failed
	ref $results->{$_}->[0]
		? push @alive, $_
		: push @reject, $_;
};

print "Connected: @alive\n" if @alive;
print "Rejected: @reject\n" if @reject;
print "Timed out: @offline\n" if @offline;
# /Real work

sub usage {
	print <<"USAGE";
Probe tcp connection to several hosts at once
Usage: $0 [ options ] host:port host:port ...
Options may include:
	--timeout <seconds> - may be fractional as well
	--help - this message
USAGE
	exit 1;
};
