#! /usr/local/bin/perl -w

use strict;
use IO::File;

eval 'use Crypt::CBC 1.22';

print "1..5\n";
if ($@) {
	print "ok # skipped in absence of Crypt::CBC 1.22 or higher\n"
		x 5;
	exit 0;
} else {
	print "ok 1\n";
}

my @algos = qw (Twofish_PP 
                Twofish_PP::Key16 Twofish_PP::Key24 Twofish_PP::Key32);

for my $i (2 .. 5) {
	my $copying;

	my $fh;
	my $here = $0;
	$here =~ m@^(.*)[\\/].*$@;
	$here = $1 || '.';

	local $/;
	$fh = IO::File->new ("<$here/../Artistic")
		or die;

	$copying = <$fh>;
	die unless defined $copying;
	$fh->close;

	eval {
		my $key = 'Not very secret';
		my $cipher;
	
		$cipher = Crypt::CBC->new ($key, shift @algos)
			or die;

		my $result = $cipher->decrypt ($cipher->encrypt ($copying))
			or die;

		$result eq $copying or die;
	};
	print $@ ? "not ok $i\n" : "ok $i\n";
}

