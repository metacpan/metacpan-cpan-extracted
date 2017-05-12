#! /usr/local/bin/perl -w

package IO::Bi;
use IO::File;

sub new {
	my ($class, $infile, $outfile) = @_;
	bless {
		in  => IO::File->new($infile),
		out => IO::File->new("> $outfile"),
	}, $class;
}

use Class::Delegation
	send => [qw(getline getlines)],
	  to => 'in',

	send => -OTHER,
	  to => 'out',
	;

package main;

my $handle = IO::Bi->new('-', '-');

while (defined ($_ = $handle->getline)) {
	$handle->print($_);
}
