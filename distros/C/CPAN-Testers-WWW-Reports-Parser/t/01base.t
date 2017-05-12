#!/usr/bin/perl -w
use strict;

use Test::More tests => 4;

BEGIN {
	use_ok( 'CPAN::Testers::WWW::Reports::Parser' );
	use_ok( 'CPAN::Testers::WWW::Reports::Report' );

    eval "use JSON::XS";
	SKIP: {
        skip "JSON::XS required for testing JSON parser", 1 if $@;
        use_ok( 'CPAN::Testers::WWW::Reports::Parser::JSON' );
    }

    eval "use YAML::XS";
	SKIP: {
        skip "YAML::XS required for testing YAML parser", 1 if $@;
        use_ok( 'CPAN::Testers::WWW::Reports::Parser::YAML' );
    }
}
