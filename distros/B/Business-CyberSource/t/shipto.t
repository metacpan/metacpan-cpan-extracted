use strict;
use warnings;
use Test::More;
use Test::Deep;
use Test::Method;
use Test::Moose;
use Module::Runtime qw( use_module );

# purpose of this test is to check bare minimum for creation. I.e. that required attributes are ok.
my $ship_to = new_ok(
    use_module('Business::CyberSource::RequestPart::ShipTo') => [
        {
            street1        => 'Somewhere in Siberia',
            country        => 'RU',
        }
    ]
);

# purpose of this test is to check accessors and serialization
$ship_to = new_ok(
    use_module('Business::CyberSource::RequestPart::ShipTo') => [
        {

            first_name     => 'Bob',
            last_name      => 'Lemon',
            street1        => '306 E 6th',
            street2        => 'Dizzy Rooster',
            city           => 'Austin',
            state          => 'TX',
            country        => 'US',
            postal_code    => '78701',
            phone_number    => '+1(512)236-1667',
            shipping_method => 'none',

        }
    ]
);

does_ok $ship_to, 'MooseX::RemoteHelper::CompositeSerialization';
can_ok $ship_to,  'serialize';

# checking accessors without arguments, they simply return the value
method_ok $ship_to, first_name     => [], 'Bob';
method_ok $ship_to, last_name      => [], 'Lemon';
method_ok $ship_to, street1        => [], '306 E 6th';
method_ok $ship_to, street2        => [], 'Dizzy Rooster';
method_ok $ship_to, city           => [], 'Austin';
method_ok $ship_to, state          => [], 'TX';
method_ok $ship_to, country        => [], 'US';
method_ok $ship_to, postal_code    => [], '78701';
method_ok $ship_to, phone_number   => [], '+1(512)236-1667';
method_ok $ship_to, shipping_method => [], 'none';

my %expected_serialized = (
    firstName      => 'Bob',
    lastName       => 'Lemon',
    street1        => '306 E 6th',
    street2        => 'Dizzy Rooster',
    city           => 'Austin',
    state          => 'TX',
    country        => 'US',
    postalCode     => '78701',
    phoneNumber    => '+1(512)236-1667',
    shippingMethod => 'none',
);

method_ok $ship_to, serialize => [], \%expected_serialized;

done_testing;
