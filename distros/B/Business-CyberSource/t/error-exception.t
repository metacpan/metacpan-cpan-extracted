use strict;
use warnings;
use Test::More;
use Test::Fatal;
use Test::Method;
use Test::Moose;

use Module::Runtime qw( use_module );

my $factory = new_ok( use_module('Business::CyberSource::Factory::Response') );

can_ok $factory, 'create';

my $result = {
	decision     => 'ERROR',
	requestID    => '3367880563740176056428',
	reasonCode   => '150',
	requestToken => 'AhhRbwSRbSV2sdn3CQDYD6QQqAAaSZV0ekrReBEA5lFa',
};

my $exception = exception { $factory->create( $result ) };

BAIL_OUT( "no exception" ) unless $exception;

isa_ok  $exception, 'Business::CyberSource::Exception' or diag $exception;
does_ok $exception, 'Business::CyberSource::Response::Role::Base';

like     "$exception", qr/error/i, 'stringify';
method_ok $exception, decision    => [], 'ERROR';
method_ok $exception, reason_code => [],  150;

done_testing;
