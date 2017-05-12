##!/usr/bin/perl

# $Id: match_cvr.t,v 1.1 2008-06-11 08:08:00 jonasbn Exp $

use strict;
use warnings;
use Test::More;
use Test::Taint;
use Data::FormValidator;
use Env qw($TEST_COVERAGE $TEST_VERBOSE);
use Taint::Runtime qw( $TAINT taint_env taint_start );

diag "\$TEST_COVERAGE is set to $TEST_COVERAGE" if $TEST_VERBOSE;

if ($TEST_COVERAGE) {
	plan skip_all => 'Devel::Cover does not play well with taint mode';
} else {
	plan tests => 12;

	taint_start();
	taint_env();
	#taint_checking_ok('Is taint checking on'); #this does not seem to work
}

use_ok( 'Data::FormValidator::Constraints::Business::DK::CVR',
    qw(valid_cvr) );

my $dfv_profile = {
    required           => [qw(cvr)],
    constraint_methods => { cvr => valid_cvr(), }
};

my $input_hash;
my $result;

$input_hash = { cvr => 99999999, };

#Tainting data
taint_deeply($input_hash);
tainted_ok_deeply( $input_hash, 'Checking that our data are tainted' );

$result = Data::FormValidator->check( $input_hash, $dfv_profile );

ok( !$result->success, 'The data was not conforming to the profile' );

ok( $result->has_invalid,  'Checking that we have invalids' );
ok( !$result->has_unknown, 'Checking that we have no unknowns' );
ok( !$result->has_missing, 'Checking that we have no missings' );

$input_hash = { cvr => 27355021, };

ok( $result = Data::FormValidator->check( $input_hash, $dfv_profile ),
    'Calling check' );

ok( !$result->has_invalid, 'Checking that we have no invalids' );
ok( !$result->has_unknown, 'Checking that we have no unknowns' );
ok( !$result->has_missing, 'Checking that we have no missings' );

$dfv_profile = {
    required                  => [qw(cvr)],
    constraint_methods        => { cvr => valid_cvr(), },
    untaint_constraint_fields => 1,
};

ok( $result = Data::FormValidator->check( $input_hash, $dfv_profile ),
    'Calling check' );

untainted_ok_deeply( $input_hash, 'Checking that our data are tainted' );
