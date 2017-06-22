#! /usr/bin/perl

use v5.10;
use warnings;
use strict;

use Test::More tests => 1;

@ARGV = ('t/hello.bat', 'hi');
unless (-e $ARGV[0]) {
	# skip test, if 10-hello.t has not recovered hello.bat yet
	pass;
	exit;
}

	use Batch::Interpreter;

	open my $fh, '<:crlf', $ARGV[0]
		or die "$ARGV[0]: $!";

	my $rc = Batch::Interpreter->new(
		locale => 'de_DE',
		# more settings, see below
	)->run({}, [ <$fh> ], @ARGV);

is $rc, '0';
