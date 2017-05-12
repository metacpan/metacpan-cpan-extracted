# $Id$

use strict;
use warnings;
use Test::More qw(no_plan);

use Data::FormValidator;

use_ok( 'Data::FormValidator::Constraints::Business::DK::Phonenumber',
    qw(valid_dk_phonenumber) );

my $dfv_profile = {
    required           => [qw(phonenumber)],
    constraint_methods => { phonenumber => valid_dk_phonenumber(), }
};

my $input_hash;
my $result;

$input_hash = { phonenumber => 1234567, };

$result = Data::FormValidator->check( $input_hash, $dfv_profile );

ok( !$result->success );

ok( $result->has_invalid );
ok( !$result->has_unknown );
ok( !$result->has_missing );

#use Data::Dumper;
#print STDERR Dumper $result;

$input_hash = { phonenumber => 12345678, };

ok( $result = Data::FormValidator->check( $input_hash, $dfv_profile ) );

ok( !$result->has_invalid );
ok( !$result->has_unknown );
ok( !$result->has_missing );

$dfv_profile = {
    required                => [qw(phonenumber)],
    constraint_methods      => { phonenumber => valid_dk_phonenumber(), },
    untaint_all_constraints => 1,
};

ok( $result = Data::FormValidator->check( $input_hash, $dfv_profile ) );
