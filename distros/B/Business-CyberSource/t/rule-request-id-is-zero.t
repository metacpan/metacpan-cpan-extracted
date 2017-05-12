use strict;
use warnings;
use Test::More;

use Module::Runtime qw( use_module );
use FindBin; use lib "$FindBin::Bin/lib";

my $t = use_module('Test::Business::CyberSource')->new;

my $client = $t->resolve( service => '/client/object'    );
my $cc
	= $t->resolve(
		service    => '/helper/card',
		parameters => { expiration => { month => 5, year => 2010 }, },
	);

my $req0
	= $t->resolve(
		service => '/request/authorization',
		parameters => {
			purchase_totals => $t->resolve(
				service    => '/helper/purchase_totals',
                                parameters => {
                                    total    => 3000.00,
                                    discount => 50.00,
                                    duty     => 10.00
                                },    # magic ACCEPT
			),
			card  => $cc,
		},
	);

my $ret0 = $client->submit( $req0 );

my $req1
	= new_ok( use_module('Business::CyberSource::Request::Capture') => [{
		reference_code => $req0->reference_code,
		service => { request_id => $ret0->request_id },
		purchase_totals => {
			total          => 3000.00,
			discount       => 50.00,
			duty           => 10.00,
			currency       => $req0->purchase_totals->currency,
		}
	}])
	;

my $ret1 = $client->submit( $req1 );

ok ! $ret1->has_trace,  'trace not set';
is   $ret1->decision,   'REJECT', 'decision';
is   $ret1->reason_code, 241,     'reason_code';
like $ret1->reason_text, qr/The request ID is invalid/i, 'reason_text';

done_testing;
