package Test::Class::Class::Business::GL::Postalcode;

use strict;
use warnings;
use base qw(Test::Class);
use Test::More;
use Env qw($TEST_VERBOSE);
use utf8;
use Readonly;

Readonly::Scalar my $postalcodes_fixtures => '33';

sub startup : Test(startup => 3) {
    my $t = shift;

    use_ok( 'Class::Business::GL::Postalcode' );

    ok(my $validator = Class::Business::GL::Postalcode->new(), 'calling new');

    is(scalar @{$validator->postal_data()}, $postalcodes_fixtures, 'asserting number of postal codes');

    $t->{validator} = $validator;
};

sub test_postal_data : Test(1) {
    my $t = shift;

    my $validator = $t->{validator};

    is(scalar @{$validator->postal_data()}, $postalcodes_fixtures, 'asserting number of postal codes');
}

sub test_get_all_postalcodes : Test(3) {
    my $t = shift;

    my $validator = $t->{validator};

    ok(my $postalcodes_ref = $validator->get_all_postalcodes(), 'calling get all postal codes');
    is(scalar @{$postalcodes_ref}, $postalcodes_fixtures, 'asserting number of postal codes');

    is($postalcodes_ref->[0], '2412', 'asserting postal code');
}

sub test_get_all_cities : Test(3) {
    my $t = shift;

    my $validator = $t->{validator};

    ok(my $cities_ref = $validator->get_all_cities(), 'calling get all cities');
    is(scalar @{$cities_ref}, $postalcodes_fixtures, 'asserting number of postal codes');

    is($cities_ref->[0], 'Santa Claus/Julemanden', 'asserting city name');
}

# sub test_get_all_data : Test(2) {
#     my $t = shift;

#     my $validator = $t->{validator};

#     ok(my $postalcodes_ref = $validator->get_all_data(), 'calling get_all_data');

#     is(scalar(@{$postalcodes_ref}), 33, 'asserting number of postalcodes');
# }

sub test_get_postalcode_from_city : Test(2) {
    my $t = shift;

    my $validator = $t->{validator};

    ok(my $postal_codes = $validator->get_postalcode_from_city('Nuuk'), 'calling get_postalcode_from_city');

    is($postal_codes->[0], '3900', 'asserting postal code');
}

sub test_get_city_from_postalcode : Test(2) {
    my $t = shift;

    my $validator = $t->{validator};

    ok(my $city = $validator->get_city_from_postalcode('3900'), 'calling get_city_from_postalcode');

    is($city, 'Nuuk', 'asserting city');
}

sub test_validate : Test(2) {
    my $t = shift;

    my $validator = $t->{validator};

    my @invalids = qw();
    my @valids = qw();

    foreach (0 .. 9999) {
        my $number = sprintf '%04d', $_;
        if (not $validator->validate($number)) {
            push @invalids, $number;
        } else {
            push @valids, $number;
        }
    }

    is(scalar @invalids, 10000 - $postalcodes_fixtures, 'asserting number of invalids for validate');
    is(scalar @valids, $postalcodes_fixtures, 'asserting number of valids for validate');
}

1;
