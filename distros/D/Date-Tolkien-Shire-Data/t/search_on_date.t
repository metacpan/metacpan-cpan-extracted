package main;

use 5.006002;

use strict;
use warnings;

use Date::Tolkien::Shire::Data qw{ __search_on_date };
use Test::More 0.47;	# The best we can do with Perl 5.6.2.

plan tests => 3;

{
    my $want = [
	[ 2, 16 ],
	[ 9, 29 ],
    ];

    is_deeply [ __search_on_date( sub { m/depart/ } ) ], $want,
	'Search for sub { m/depart/ }';
    is_deeply [ __search_on_date( qr/depart/ ) ], $want,
	'Search for qr/depart/';
    is_deeply [ __search_on_date( 'depart' ) ], $want,
	q/Search for 'depart'/;
}

done_testing;

1;

# ex: set textwidth=72 :
