# $Id$

use strict;
use Test::More qw(no_plan);

use_ok('Business::DK::Phonenumber', qw(validate));

my $good_prefixes = [
    '+45',
    '+ 45',
    '45',
    '+45 ',
    '+ 45 ',
    '45 ',
];

my $good_numbers = [
    '12345678',
    '1234 5678',
    '12 34 56 78',
    '45454545',
];

foreach my $prefix (@{$good_prefixes}) {
    foreach my $number (@{$good_numbers}) {
        my $phonenumber = $prefix . $number;
        ok(validate($phonenumber), "Asserting: $phonenumber, should pass");
    }
}

my $bad_prefixes = [
    '+46',
    '+ 46',
    '46',
    '+46 ',
    '+ 46 ',
    '46 ',
    '+',
    '+ ',
];

my $bad_numbers = [
    '123456',
    '1234567',
    '1234 567',
    '12 34 56 7',
    '4545457',
];

foreach my $prefix (@{$bad_prefixes}) {
    foreach my $number (@{$bad_numbers}) {
        my $phonenumber = $prefix . $number;
        if (length $number == 6 && $prefix !~ m/\+/) {
            ok(validate($phonenumber), "Asserting: $phonenumber, should pass");
        } else {
            ok(! validate($phonenumber), "Asserting: $phonenumber, should not pass");
        }
    }
}

