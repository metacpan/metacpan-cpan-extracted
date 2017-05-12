use strict;
use warnings;
use Test::More;
use Test::Deep;
use Test::Method;

use Module::Runtime qw( use_module );
use FindBin; use lib "$FindBin::Bin/lib";

my $t = use_module('Test::Business::CyberSource')->new;

my $client = $t->resolve( service => '/client/object' );
my $cc
	= $t->resolve(
		service    => '/helper/card',
		parameters => { expiration => { month => 5, year => 2010 }, },
	);

is( $cc->expiration->year, 2010, 'expiration year' );
ok( $cc->is_expired, 'card expired' );

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

isa_ok $ret0, 'Business::CyberSource::Response';

ok ! $ret0->has_trace, 'does not have trace';

method_ok $ret0, is_accept   => [], bool(0);
method_ok $ret0, decision    => [], 'REJECT';
method_ok $ret0, reason_code => [], '202';
method_ok $ret0, reason_text => [],
	'Expired card. You might also receive this if the expiration date you '
	. 'provided does not match the date the issuing bank has on file'
	;

done_testing;
