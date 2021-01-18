#!/usr/bin/perl

use strict;
use warnings;
use if $ENV{AUTOMATED_TESTING}, 'Test::DiagINC'; use Test::More;
use Data::FormValidator;
use Data::FormValidator::Constraints::NumberPhone qw(
    FV_american_phone
    FV_telephone
);

###############################################################################
subtest 'test_telephone' => sub {
    my $is_telephone_valid = sub {
        my $country = shift;
        my $num     = shift;
        my $results = Data::FormValidator->check( {
            num => $num,
        }, {
            required => [qw( num )],
            constraint_methods => {
                num => FV_telephone($country),
            },
        } );
        my $valid = $results->valid;
        return $valid->{num};
    };

    ok  $is_telephone_valid->('ca' => '604.555.1212'),  'valid Canadian number';
    ok !$is_telephone_valid->('ca' => '915-555-1212'),  'US number not valid in Canada';
    ok  $is_telephone_valid->('us' => '915-555-1212'),  'valid US number';
    ok !$is_telephone_valid->('us' => '999-999-9999'),  'IN-valid US number';
    ok  $is_telephone_valid->('uk' => '+442087712924'), 'valid UK number';
    ok !$is_telephone_valid->('uk' => '+1-604-555-1212'),  'Canadian number not valid in UK';

    ###########################################################################
    subtest 'without country' => sub {
        my $results = Data::FormValidator->check( {
            num => '604-555-1212',
        }, {
            required => [qw( num )],
            constraint_methods => {
                num => FV_telephone(),
            }
        } );
        my $valid = $results->valid;
        ok !$valid->{num}, 'cannot valid phone number w/o country';
    };
};

###############################################################################
subtest 'test_american_phone' => sub {
    my $is_american_phone_valid = sub {
        my $num     = shift;
        my $results = Data::FormValidator->check( {
            num => $num,
        }, {
            required => [qw( num )],
            constraint_methods => {
                num => FV_american_phone(),
            },
        } );
        my $valid = $results->valid;
        return $valid->{num};
    };

    ok  $is_american_phone_valid->('604-555-1212'),       'valid North American phone number';
    ok  $is_american_phone_valid->('+1-250-555-1212'),    'valid North American phone number, w/prefix';
    ok  $is_american_phone_valid->('1-778-555-1212'),     'valid North American mobile number';
    ok !$is_american_phone_valid->('441-555-1212'),       'invalid; not in a North American country';
    ok !$is_american_phone_valid->('not a phone number'), 'invalid; not a phone number';
    ok !$is_american_phone_valid->('000-000-000'),        'invalid; invalid number';
    ok !$is_american_phone_valid->('+442087712924'),      'invalid; not a NANP number';
};

###############################################################################
done_testing();
