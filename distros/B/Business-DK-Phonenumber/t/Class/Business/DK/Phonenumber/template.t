# $Id$

use strict;
use Test::More qw(no_plan);

use_ok('Class::Business::DK::Phonenumber');

ok(my $phonenumber = Class::Business::DK::Phonenumber->new({ phonenumber => '12345678' }));

is($phonenumber->template(), '+45 %08d');

ok($phonenumber->template('%08d'));

is($phonenumber->template(), '%08d');

ok(! $phonenumber->template('d8'));

