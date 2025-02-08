#!perl -wT

use strict;
use warnings;
use Test::Most tests => 3;

BEGIN {
	use_ok('CGI::Lingua');
}

CARP: {
	eval 'use Test::Carp';

	if($@) {
		plan(skip_all => 'Test::Carp needed to check error messages');
	} else {
		does_croak_that_matches(sub { CGI::Lingua->new(); }, qr/You must give a list of supported languages/);
		does_croak_that_matches(sub { CGI::Lingua->new(supported => undef); }, qr/You must give a list of supported languages/);
	}
}
