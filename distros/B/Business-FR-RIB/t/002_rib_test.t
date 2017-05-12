# -*- perl -*-

# t/002_rib_test.t - check module working

use strict;
use warnings;
use Test::More tests => 9;

use Business::FR::RIB;

my $object = Business::FR::RIB->new();
ok($object->is_valid('1234567890DWFACEOFBOE08'), 'RIB validity, is_valid input');

ok($object->is_valid(), 'RIB validity, constructor input');

ok($object->get_code_banque() == 12345, 'Checking bank code retrieval');

ok($object->get_code_guichet() == 67890, 'Checking counter code retrieval');

ok($object->get_no_compte() eq 'DWFACEOFBOE', 'Checking account number retrieval');

ok($object->get_cle_rib() eq '08', 'Checking RIB key retrieval');

ok($object->rib() eq '1234567890DWFACEOFBOE08', 'Checking RIB retrieval');

ok($object->rib('1234567890DWFACEOFBOE07') eq '1234567890DWFACEOFBOE07', 'Checking RIB setting');

ok(!$object->is_valid(), 'RIB unvalidity');
