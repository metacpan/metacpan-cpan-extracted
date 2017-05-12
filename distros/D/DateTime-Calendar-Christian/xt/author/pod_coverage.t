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


{
    # all_pod_coverage_ok() will load the module for us, but we load it
    # explicitly because we want to tinker with its inheritance.
    require DateTime::Calendar::Christian;

    # This hack causes all DateTime methods to be considered documented.
    # Wish there was a cleaner way.
    local @DateTime::Calendar::Christian::ISA = qw{ DateTime };

    all_pod_coverage_ok ({
	    also_private => [
		qr{ \A [[:upper:]\d_]+ \z }smx,
	    ],
	    # The following are DateTime methods not documented by that
	    # module in any way that Pod::Coverage recognizes
	    trustme	=> [
		qr{ \A day_0 \z }smx,
		qr{ \A day_of_ (?: month (?: _0 )? | week_0 | quarter_0 |
		    year_0 ) \Z }smx,
		qr{ \A do [qwy] (?: _0 )? \z }smx,
		qr{ \A era \z }smx,
		qr{ \A iso8601 \z }smx,
		qr{ \A local_rd_as_seconds \Z }smx,
		qr{ \A mday (?: _0 )? \z }smx,
		qr{ \A min \z }smx,
		qr{ \A mon (?: (?: th )? _0 )? \z }smx,
		qr{ \A quarter_0 \z }smx,
		qr{ \A sec \z }smx,
		qr{ \A STORABLE_ (?: freeze | thaw ) \z }smx,
		qr{ \A utc_year \z }smx,
		qr{ \A wday (?: _0 )? \z }smx,
	    ],
	    coverage_class => 'Pod::Coverage::CountParents'
	});

}
1;

# ex: set textwidth=72 :
