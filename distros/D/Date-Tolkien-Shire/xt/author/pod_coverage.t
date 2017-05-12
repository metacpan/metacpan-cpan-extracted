package main;

use strict;
use warnings;

use Test::More 0.88;

BEGIN {
    eval {
	require Test::Pod::Coverage;
	Test::Pod::Coverage->VERSION(1.00);
	Test::Pod::Coverage->import();
	1;
    } or do {
	print <<eod;
1..0 # skip Test::Pod::Coverage 1.00 or greater required.
eod
	exit;
    };
}

all_pod_coverage_ok ({
	also_private => [ qr{^[[:upper:]\d_]+$}, ],
	coverage_class => 'Pod::Coverage::CountParents',
	trustme => [
	    # The following match methods inherited from DateTime
	    # (whether or not overridden), but not documented there.
	    qr{ \A day .* _0 \z }smx,
	    qr{ \A (?: day_of_month | mday ) \z }smx,
	    qr{ \A (?: dow | mday | mon | month | quarter | wday ) _0 \z }smx,
	    qr{ \A iso8601 \z }smx,
	    # The following match methods inherited from
	    # DateTime::Locale::FromData (whether or not overridden),
	    # but not documented there.
	    qr{ \A new \z }smx,
	],
    });

1;

# ex: set textwidth=72 :
