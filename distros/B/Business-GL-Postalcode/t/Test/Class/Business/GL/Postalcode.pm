package Test::Class::Business::GL::Postalcode;

use strict;
use warnings;
use base qw(Test::Class);
use Test::More;
use Env qw($TEST_VERBOSE);
use Readonly;

Readonly::Scalar my $postalcodes_fixtures => '33';

sub startup : Test(startup => 1) {
    use_ok( 'Business::GL::Postalcode', qw(get_all_postalcodes get_all_cities get_all_data validate_postalcode validate get_postalcode_from_city get_city_from_postalcode));
};

sub test_get_all_postalcodes : Test(3) {
    ok(my $postalcodes_ref = get_all_postalcodes(), 'calling get_all_postalcodes');
    is(scalar @{$postalcodes_ref}, $postalcodes_fixtures, 'asserting number of postal codes');

    is($postalcodes_ref->[0], '2412', 'asserting postal code');
}

sub test_get_all_cities : Test(3) {
    ok(my $cities_ref = get_all_cities(), 'calling get_all_cities');
    is(scalar @{$cities_ref}, $postalcodes_fixtures, 'asserting number of postal codes');

    is($cities_ref->[0], 'Santa Claus/Julemanden', 'asserting city name');
}

sub test_get_all_data : Test(2) {
    ok(my $postalcodes_ref = get_all_data(), 'calling get_all_data');

    is(scalar @{$postalcodes_ref}, $postalcodes_fixtures, 'asserting number of postal codes');
}

sub test_validate_postalcode : Test(2) {
    my $self = shift;

    my @invalids = qw();
    my @valids = qw();

    foreach (0 .. 9999) {
        my $number = sprintf '%04d', $_;
        if (not validate_postalcode($number)) {
            push @invalids, $number;
        } else {
            push @valids, $number;
        }
    }

    is(scalar @invalids, 10000 - $postalcodes_fixtures, 'asserting number of invalids for validate_postalcode');
    is(scalar @valids, $postalcodes_fixtures, 'asserting number of valids for validate_postalcode');
}

sub test_validate : Test(2) {
    my $self = shift;

    my @invalids = qw();
    my @valids = qw();

    foreach (0 .. 9999) {
        my $number = sprintf '%04d', $_;
        if (not validate($number)) {
            push @invalids, $number;
        } else {
            push @valids, $number;
        }
    }

    is(scalar @invalids, 10000 - $postalcodes_fixtures, 'asserting number of invalids for validate');
    is(scalar @valids, $postalcodes_fixtures, 'asserting number of valids for validate');
}

sub test_get_postalcode_from_city : Test(2) {
    my $t = shift;

    ok(my $postal_codes = get_postalcode_from_city('Nuuk'), 'calling get_postalcode_from_city');

    is($postal_codes->[0], '3900', 'asserting postal code');
}

sub test_get_city_from_postalcode : Test(2) {
    my $t = shift;

    ok(my $city = get_city_from_postalcode('3900'), 'calling get_city_from_postalcode');

    is($city, 'Nuuk', 'asserting city');
}

1;
