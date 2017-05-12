#!/usr/bin/perl -w

# $Id$

use strict;
use Test::More tests => 4;

use_ok('Business::DK::Phonenumber', qw(render));

my $phonenumber = '12345678';
my $template = '%2d %2d %2d %2d';
my $fixture = '12 34 56 78';

ok(my $renderedphonenumber = render($phonenumber, $template));

is($renderedphonenumber, $fixture);

is(render($renderedphonenumber, $template), $fixture);

print STDERR render($renderedphonenumber, $template);
