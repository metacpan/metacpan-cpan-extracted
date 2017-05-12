use strict;
use warnings;
use Test::More;
use Test::Moose;
use Test::Method;
use Module::Runtime qw( use_module );

my $dto
	= new_ok( use_module('Business::CyberSource::RequestPart::PurchaseTotals') => [{
		total    => 5.00,
		currency => 'USD',
                discount => 0.05,
                duty     => 0.01,
	}]);

my %expected
	= (
		grandTotalAmount => 5.00,
		currency         => 'USD',
                discountAmount   => 0.05,
                dutyAmount       => 0.01,
	);

method_ok $dto, total     => [], 5.00;
method_ok $dto, currency  => [], 'USD';
method_ok $dto, discount  => [], 0.05;
method_ok $dto, duty      => [], 0.01;
method_ok $dto, serialize => [], \%expected;

done_testing;
