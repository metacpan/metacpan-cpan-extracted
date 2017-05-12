#! /usr/bin/perl

use strict;
use warnings;
use Test::More;

BEGIN: {
    unless (use_ok('Appium::TouchActions')) {
        BAIL_OUT("Couldn't load Appium::TouchActions");
        exit;
    }
}

my $actions;
{
    package FakeAppium;

    use Moo;
    sub execute_script {
        my ($self, $action, $json) = @_;

        $actions->{$action} = $json;
    }
}

my $fake_appium = FakeAppium->new;

my $ta = Appium::TouchActions->new(
    driver => $fake_appium
);

TOUCH_ACTIONS: {
    my ($x, $y) = (0.2, 0.2);
    $ta->tap( $x, $y );

    ok(exists $actions->{'mobile: tap'}, 'we send the correct javascript for precise taps');
    is($actions->{'mobile: tap'}->{x}, $x, 'with the correct x coords');
    is($actions->{'mobile: tap'}->{y}, $y, 'with the correct y coords');

}

done_testing;
