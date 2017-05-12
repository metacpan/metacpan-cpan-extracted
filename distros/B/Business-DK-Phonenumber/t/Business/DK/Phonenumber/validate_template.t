# $Id$

use strict;
use Test::More qw(no_plan);

use_ok('Class::Business::DK::Phonenumber');

ok(my $phonenumber = Class::Business::DK::Phonenumber->new({ phonenumber => '12345678' }));

ok(! $phonenumber->validate_template('xxx'));

ok(! $phonenumber->validate_template('8d'));

ok(! $phonenumber->validate_template('d8'));

ok(! $phonenumber->validate_template('d8%'));

ok(! $phonenumber->validate_template('d%8'));

ok(! $phonenumber->validate_template('%02d %02d %02d %01d'));

ok(! $phonenumber->validate_template('%04d %03d'));

ok($phonenumber->validate_template('%08d'));

ok($phonenumber->validate_template('%02d %02d %02d %02d'));

ok($phonenumber->validate_template('%04d %04d'));
