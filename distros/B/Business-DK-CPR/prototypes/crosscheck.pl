#!/usr/bin/perl

# $Id$
use strict;
use warnings;
use Test::More tests => 909;
use Business::DK::CPR qw(
    generate1968
    validate2007
    generate2007
    validate1968
);

my @cprs;

@cprs = generate1968(150172, 'female');

foreach (@cprs) {
    ok(validate2007($_), "Validating: $_");
}

@cprs = generate1968(150172, 'male');

foreach (@cprs) {
    ok(validate2007($_), "Validating: $_");
}
