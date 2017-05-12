#!/usr/bin/perl -w
use strict;

use Test::More tests => 1;
use Acme::OSDc;
use File::Spec;
use Fcntl qw(SEEK_SET);

my $osdC = File::Spec->catfile("OSDc","prog.osdc");
my $OSDc = Acme::OSDc->new;

print "$osdC\n";

SKIP: {
	if ($] < 5.008) { skip "5.008 tempfiles required",1 }

	my $results;

	{
		local *STDOUT;
		open(STDOUT,"+>", undef);
		my $jon = $OSDc->compile($osdC);
		eval $jon;
		seek(STDOUT,0,SEEK_SET);
		$results = <STDOUT>;
	}
	is($results,"OSDc - where crazy stuff happens\n");
}

