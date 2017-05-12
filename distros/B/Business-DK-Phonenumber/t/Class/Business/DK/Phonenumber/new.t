# $Id$

use strict;
use Test::More qw(no_plan);
use Test::Exception;

use_ok('Class::Business::DK::Phonenumber');

dies_ok { my $phonenumber = Class::Business::DK::Phonenumber->new(), 'No phonenumber argument' };

dies_ok { my $phonenumber = Class::Business::DK::Phonenumber->new({ phonenumber => '1234' }), 'Invalid phonenumber argument' };

my $phonenumber;

ok($phonenumber = Class::Business::DK::Phonenumber->new({ phonenumber => '12345678' }));

isa_ok($phonenumber, 'Class::Business::DK::Phonenumber');

ok($phonenumber = Class::Business::DK::Phonenumber->new({ phonenumber => '12345678', template => '%8d' }));

isa_ok($phonenumber, 'Class::Business::DK::Phonenumber');