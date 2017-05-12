#!perl -w

use strict;
use warnings;
use Test::Most;

eval 'use Test::CGI::Untaint';

if($@) {
        plan skip_all => 'Test::CGI::Untaint required for testing extraction handler';
} else {
        plan tests => 4;

        use_ok('CGI::Untaint::Twitter');
	# use_ok('CGI::Untaint::Twitter', { consumer_key => 'xxxx' etc. });

	SKIP: {
		skip 'Twitter API1.1 needs authentication', 3;

		is_extractable('nigelhorne', 'nigelhorne', 'Twitter');
		is_extractable('@nigelhorne', 'nigelhorne', 'Twitter');
		unextractable('&^&', 'Twitter');
	}
}
