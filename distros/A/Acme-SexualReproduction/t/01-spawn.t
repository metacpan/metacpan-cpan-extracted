#!/usr/bin/perl
use warnings;
use strict;
use Acme::SexualReproduction qw(male female);
#use Test::Simple tests => 4;
print "1..4\n";
my $key = int rand 10000;
if (fork) {
	sleep 1; # foreplay
	print "ok\n" if male($key, {a => 1, b => 1});
} else {
	my %genes = (
		a => 2,
		b => 2,
	);
	my $pid = female($key, \%genes);
	if ($pid == 0) {
		print qq'# genes = @genes{"a","b"}\n';
		for (qw/a b/) {print "ok\n" if $genes{$_} == 1 or $genes{$_} == 2}
	} else {
		print "# pid = $pid\n";
		print "ok\n" if $pid;
		sleep 1;
	}
}
