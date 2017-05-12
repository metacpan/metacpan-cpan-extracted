use strict;
use warnings;
use Test::More;
use Test::Deep;
use Test::Method;
use Test::Moose;
use Module::Runtime qw( use_module );

my $Module = 'Business::CyberSource::RequestPart::ShipFrom';

my $shipform = new_ok(
    use_module($Module) => [
        {
            postal_code => '78752',
        }
    ]
);

does_ok $shipform, 'MooseX::RemoteHelper::CompositeSerialization';
can_ok $shipform,  'serialize';

method_ok $shipform, postal_code => [], '78752';

my %expected_serialized = (
    postalCode => '78752',
);

method_ok $shipform, serialize => [], \%expected_serialized;

my $shipform1 = new_ok(
    use_module($Module) => [
        {
            postalCode => '78752',
        }
    ]
);

done_testing;
