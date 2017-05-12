use strict;
use warnings;
use Test::More;
use Test::Requires qw( MooseX::AbstractFactory );

use Module::Runtime qw( use_module );

my $factory = new_ok( use_module('Business::CyberSource::Factory::Request') );

can_ok $factory, 'create';

done_testing;
