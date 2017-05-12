#!/usr/bin/perl -T

# $Id$

use strict;
use warnings;
use Test::More qw(no_plan);
use Test::Taint;
use Data::FormValidator;

use Taint::Runtime qw(enable taint_start taint_enabled);
taint_start();

taint_checking_ok('Is taint checking on'); 

use_ok('Data::FormValidator::Constraints::Business::DK::Phonenumber', qw(valid_dk_phonenumber));

my $dfv_profile = {
    required => [qw(phonenumber)],
    constraint_methods => {
        phonenumber => valid_dk_phonenumber(),
    }
};

my $input_hash;
my $result;

$input_hash = {
    phonenumber  => 1234567,
};

#Tainting data
taint_deeply($input_hash);
tainted_ok_deeply($input_hash, 'Checking that our data are tainted');

#Calling check, resolved to false in boolean context
$result = Data::FormValidator->check($input_hash, $dfv_profile);

ok(! $result->success, 'The data was not conforming to the profile');

ok($result->has_invalid, 'Checking that we have invalids');
ok(! $result->has_unknown, 'Checking that we have no unknowns');
ok(! $result->has_missing, 'Checking that we have no missings');

tainted_ok_deeply($input_hash, 'Checking that our data are tainted');

$input_hash = {
    phonenumber => 12345678,
};

ok($result = Data::FormValidator->check($input_hash, $dfv_profile), 'Calling check');

ok(! $result->has_invalid, 'Checking that we have no invalids');
ok(! $result->has_unknown, 'Checking that we have no unknowns');
ok(! $result->has_missing, 'Checking that we have no missings');

$dfv_profile = {
    required => [qw(phonenumber)],
    constraint_methods => {
        phonenumber => valid_dk_phonenumber(),
    },
    untaint_all_constraints => 1,
};

ok($result = Data::FormValidator->check($input_hash, $dfv_profile), 'Calling check');

untainted_ok_deeply($input_hash, 'Checking that our data are tainted');