#!/usr/bin/perl -w

use strict;
use Test::More tests => 1;
use File::Spec;
open(NULL, ">", File::Spec->devnull);

BEGIN { 
	*CORE::GLOBAL::exit = sub { 
		CORE::exit if $_[0] && $_[0] eq 'yes';
		die "exit ok\n";
	};
}

eval {
	local @ARGV = ('-v');
	select NULL;
	require 'scripts/lc.pl';
};

like($@,qr/\Aexit ok\n/s,'scripts/lc.pl compiled ok');
