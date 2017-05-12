use strict;
use warnings;
use Test::More;
use Test::Deep;
use Test::Method;
use Test::Moose;
use Module::Runtime qw( use_module );

my $dto
	= new_ok( use_module('Business::CyberSource::RequestPart::BusinessRules') => [{
		ignore_avs_result => 1,
		ignore_cv_result  => 1,
		score_threshold   => 8,
		decline_avs_flags => [qw( Y N )],
	}]);

method_ok $dto, ignore_avs_result => [], bool(1);
method_ok $dto, ignore_cv_result  => [], bool(1);
method_ok $dto, score_threshold   => [], 8;
method_ok $dto, decline_avs_flags => [], [qw( Y N )];

my %expected
	= (
		ignoreAVSResult => 'true',
		ignoreCVResult  => 'true',
		scoreThreshold  => 8,
		declineAVSFlags => 'Y N',
	);

method_ok $dto, serialize => [], \%expected;

done_testing;
