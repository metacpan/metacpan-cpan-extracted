package main;

use strict;
use warnings;

use Test::More 0.47;	# The best we can do with Perl 5.6.2.

BEGIN {
    eval {
	require Test::CPAN::Changes;
	Test::CPAN::Changes->import();
	1;
    } or do {
	plan skip_all => 'Unable to load Test::CPAN::Changes';
	exit;
    };
}

changes_ok( { next_token => 'next_release' } );

1;

# ex: set textwidth=72 :
