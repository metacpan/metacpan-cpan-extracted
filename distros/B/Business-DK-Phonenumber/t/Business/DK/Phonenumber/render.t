# $Id$

use strict;
use Test::More qw(no_plan);

use Business::DK::Phonenumber;

my $phonenumber = '12345678';

is(Business::DK::Phonenumber::render($phonenumber, '%04d %04d'), '1234 5678');

is(Business::DK::Phonenumber->render($phonenumber, '%04d %04d'), '1234 5678');

is(Business::DK::Phonenumber::render($phonenumber, '%02d %02d %02d %02d'), '12 34 56 78');

is(Business::DK::Phonenumber->render($phonenumber, '%02d %02d %02d %02d'), '12 34 56 78');
