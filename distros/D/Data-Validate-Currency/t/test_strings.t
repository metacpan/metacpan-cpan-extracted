#! /usr/bin/perl

use strict;
use warnings;
use Test::Most;

use Data::Validate::Currency qw( is_currency );


subtest "Zero dollars" => sub {

    my $zero = '0.00';
    my $validation = is_currency($zero);
    cmp_ok( $validation, '==', 1,
        'correctly returned true' );
};

subtest "No args- invalid" => sub {

    my $bad_args;
    dies_ok {
        my $validation = is_currency($bad_args);
    } 'died ok with no args';

};

subtest "Three decimal numbers" => sub {

    my $triple_dec = '123.456';
    my $validation = is_currency($triple_dec);

    cmp_ok($validation, '==', 1,
        'correctly returned true');
};

subtest "One dollar" => sub {

    my $one_dollar = '$1.00';
    my $validation = is_currency($one_dollar);

    cmp_ok( $validation, '==', 1,
        'correctly returned true' );
};
subtest "One hundred dollars no dollar sign" => sub {

    my $one_hundred_dollars = '100.00';
    my $validation = is_currency($one_hundred_dollars);

    cmp_ok( $validation, '==', 1,
        'correctly returned true' );
};

subtest "One thousand dollars" => sub {

    my $one_thousand = '$1,000.00';
    my $validation = is_currency($one_thousand);

    cmp_ok( $validation, '==', 1,
        'correctly returned true' );
};

subtest "Bad data" => sub {

    my $bad_data = '$56,6,7,8,4,32,6,f,l337.00';

    my $validation = is_currency($bad_data);
    cmp_ok( $validation, '==', 0,
        'correctly returned false' );
};

subtest "One million dollars" => sub {

    my $million = '1,000,000.00';
    my $validation = is_currency($million);

    cmp_ok( $validation, '==', 1,
        'correctly returned true');

};
subtest "999 million dollars" => sub {

    my $almost_billion = '999,000,000.00';
    my $validation = is_currency($almost_billion);

    cmp_ok( $validation, '==', 1,
        'correctly returned true');

};


subtest "One billion dollars" => sub {
    my $billion = '1,000,000,000.00';
    my $validation = is_currency($billion);

    cmp_ok( $validation, '==', 1,
        'correctly returned true');


};

subtest "One trillion dollars" => sub {
    my $trillion = '1,000,000,000,000.00';
    my $validation = is_currency($trillion);
    cmp_ok( $validation, '==', 1,
        'correctly returned true');


};

subtest "Quadrillion dollars" => sub {

    my $quadrillion = '1,000,000,000,000,000.00';
    my $validation = is_currency($quadrillion);

    cmp_ok( $validation, '==', 1,
        'correctly returned true');
};

subtest "Quintillion dollars" => sub {
    my $quintillion = '1,000,000,000,000,000,000.00';
    my $validation = is_currency($quintillion);

    cmp_ok( $validation, '==', 1,
        'correctly returned true');
};

subtest "Sextillion dollars" => sub {

    my $sextillion = '1,000,000,000,000,000,000,000.00';
    my $validation = is_currency($sextillion);

    cmp_ok( $validation, '==', 1,
        'correctly returned true');
};

subtest "Octillion dollars" => sub {

    my $octillion = '$1,000,000,000,000,000,000,000,000.00';
    my $validation = is_currency($octillion);

    cmp_ok( $validation, '==', 1,
        'correctly returned true');
};

done_testing;
