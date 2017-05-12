#!/usr/bin/perl -w
package MyPackage;

use base qw(Net::Server);

sub process_request {
	my $self = shift;
	while (<STDIN>) {
		s/\r?\n$//;
		last if /quit/i;
		print STDERR "GOT: $_\n";
		@r = `./bin/handle_query.pl "$_"`;
		print STDERR "R ".scalar @r." lines\n\n";
		print scalar @r . "\n";
		foreach (@r) { print $_; }
	}
}

MyPackage->run(port => 9999);
