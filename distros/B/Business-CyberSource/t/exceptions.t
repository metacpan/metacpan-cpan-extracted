use strict;
use warnings;
use Test::More;
use Test::Fatal;

use Module::Runtime 'use_module';
use FindBin; use lib "$FindBin::Bin/lib";

my $t = new_ok( use_module('Test::Business::CyberSource') );

my $authc = use_module('Business::CyberSource::Request::Authorization');

my $ptc = use_module('Business::CyberSource::RequestPart::PurchaseTotals');

my $ptotals = new_ok( $ptc => [{ currency => 'USD' }]);

my $auth
	= $authc->new({
		reference_code  => $t->resolve(
				service => '/request/reference_code'
			),
			bill_to         => $t->resolve( service => '/helper/bill_to' ),
			card            => $t->resolve( service => '/helper/card' ),
			purchase_totals => $ptotals,
	});

my $exception2 = exception { $auth->serialize };

like $exception2, qr/you must define either items or total/, 'check either items or total';

done_testing;
