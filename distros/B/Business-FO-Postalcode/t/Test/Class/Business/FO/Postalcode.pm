package Test::Class::Business::FO::Postalcode;

use strict;
use warnings;
use base qw(Test::Class);
use Test::More;
use Env qw($TEST_VERBOSE);
use Readonly;
use utf8;

Readonly::Scalar my $postalcodes_fixtures => '130';

sub startup : Test(startup => 1) {
    use_ok( 'Business::FO::Postalcode', qw(get_all_postalcodes get_all_cities get_all_data validate_postalcode validate get_postalcode_from_city get_city_from_postalcode));
};

sub test_get_all_postalcodes : Test(3) {
    ok(my $postalcodes_ref = get_all_postalcodes(), 'calling get all postalcodes');
    is(scalar @{$postalcodes_ref}, $postalcodes_fixtures, 'asserting number of postalcodes');

    is($postalcodes_ref->[0], '100', 'asserting postal code');
}

sub test_get_all_cities : Test(3) {
    ok(my $cities_ref = get_all_cities(), 'calling get all postalcodes');
    is(scalar @{$cities_ref}, $postalcodes_fixtures, 'asserting number of postalcodes');

    is($cities_ref->[0], 'Tórshavn', 'asserting city name');
}

sub test_get_all_data : Test(2) {
    ok(my $postalcodes_ref = get_all_data(), 'calling get_all_data');

    is(scalar @{$postalcodes_ref}, $postalcodes_fixtures, 'asserting number of postalcodes');
}

sub test_validate_postalcode : Test(2) {
    my $self = shift;

    my @invalids = qw();
    my @valids = qw();

    foreach (0 .. 999) {
        my $number = sprintf '%04d', $_;
        if (not validate_postalcode($number)) {
            push @invalids, $number;
        } else {
            push @valids, $number;
        }
    }

    is(scalar @invalids, 1000 - $postalcodes_fixtures, 'asserting number of invalids for validate_postalcode');
    is(scalar @valids, $postalcodes_fixtures, 'asserting number of valids for validate_postalcode');
}

sub test_validate : Test(2) {
    my $self = shift;

    my @invalids = qw();
    my @valids = qw();

    foreach (0 .. 999) {
        my $number = sprintf '%04d', $_;
        if (not validate($number)) {
            push @invalids, $number;
        } else {
            push @valids, $number;
        }
    }

    is(scalar @invalids, 1000 - $postalcodes_fixtures, 'asserting number of invalids for validate');
    is(scalar @valids, $postalcodes_fixtures, 'asserting number of valids for validate');
}

sub test_get_postalcode_from_city : Test(2) {
    my $t = shift;

    ok(my $postal_codes = get_postalcode_from_city('Árnafjørdur'), 'calling get_postalcode_from_city');

    is($postal_codes->[0], '727', 'asserting postal code');
}

sub test_get_city_from_postalcode : Test(2) {
    my $t = shift;

    ok(my $city = get_city_from_postalcode('727'), 'calling get_city_from_postalcode');

    is($city, 'Árnafjørdur', 'asserting city');
}

1;
