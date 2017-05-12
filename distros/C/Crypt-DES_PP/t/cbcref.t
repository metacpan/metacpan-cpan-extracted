#! /usr/local/bin/perl -w

use strict;
use IO::File;

eval 'use Crypt::CBC 1.22';

print "1..2\n";
if ($@) {
	print "ok # skipped in absence of Crypt::CBC 1.22 or higher\n"
		x 2;
	exit 0;
} else {
	print "ok 1\n";
}

my $copying;
eval {
	my $fh;
	my $here = $0;
	$here =~ m@^(.*)[\\/].*$@;
	$here = $1 || '.';

	local $/;
	$fh = IO::File->new ("<$here/../COPYING.LIB")
		or die;

	$copying = <$fh>;
	die unless defined $copying;
	$fh->close;

	my $key = 'Not very secret';
	my $cipher;
	
	$cipher = Crypt::CBC->new ($key, 'DES_PP')
		or die;

	my $result = $cipher->decrypt ($cipher->encrypt ($copying))
		or die;

	$result eq $copying or die;
};
print $@ ? "not ok 2\n" : "ok 2\n";

