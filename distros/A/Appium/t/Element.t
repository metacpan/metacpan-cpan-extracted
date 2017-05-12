#! /usr/bin/perl

use strict;
use warnings;
use Test::More;
use Cwd qw/abs_path/;

BEGIN: {
    my $test_lib = abs_path(__FILE__);
    $test_lib =~ s/(.*)\/.*\.t$/$1\/lib/;
    push @INC, $test_lib;
    require MockAppium;

    unless (use_ok('Appium::Element')) {
        BAIL_OUT("Couldn't load Appium::Element");
        exit;
    }
}

my $mock_appium = MockAppium->new;
my $elem = Appium::Element->new(
    id => 0,
    driver => $mock_appium
);

done_testing;
