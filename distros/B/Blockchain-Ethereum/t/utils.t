#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Blockchain::Ethereum::Utils;

subtest 'parse_units with constants' => sub {
    is parse_units('1',     WEI),   '1',                   'parse 1 wei';
    is parse_units('1',     GWEI),  '1000000000',          'parse 1 gwei';
    is parse_units('1',     ETHER), '1000000000000000000', 'parse 1 ether';
    is parse_units('1.5',   ETHER), '1500000000000000000', 'parse 1.5 ether';
    is parse_units('0.001', ETHER), '1000000000000000',    'parse 0.001 ether';
    is parse_units('20',    GWEI),  '20000000000',         'parse 20 gwei';
};

subtest 'parse_units with strings' => sub {
    is parse_units('1',    'wei'),    '1',                   'parse 1 wei string';
    is parse_units('1',    'gwei'),   '1000000000',          'parse 1 gwei string';
    is parse_units('1',    'ether'),  '1000000000000000000', 'parse 1 ether string';
    is parse_units('1',    'eth'),    '1000000000000000000', 'parse 1 eth string';
    is parse_units('5.25', 'finney'), '5250000000000000',    'parse 5.25 finney';
};

subtest 'parse_units with numeric decimals' => sub {
    is parse_units('1',   0), '1',           'parse with 0 decimals';
    is parse_units('1',   6), '1000000',     'parse with 6 decimals';
    is parse_units('100', 8), '10000000000', 'parse with 8 decimals';
    is parse_units('2.5', 4), '25000',       'parse 2.5 with 4 decimals';
};

subtest 'parse_units with different number formats' => sub {
    is parse_units('5.',   GWEI),  '5000000000',       'parse trailing decimal';
    is parse_units('.5',   GWEI),  '500000000',        'parse leading decimal';
    is parse_units('1e-3', ETHER), '1000000000000000', 'parse scientific notation';
    is parse_units('-5',   GWEI),  '-5000000000',      'parse negative number';
    is parse_units(' 10 ', GWEI),  '10000000000',      'parse with whitespace';
};

subtest 'format_units with constants' => sub {
    is format_units('1',                   WEI),   '1',     'format 1 wei';
    is format_units('1000000000',          GWEI),  '1',     'format 1 gwei';
    is format_units('1000000000000000000', ETHER), '1',     'format 1 ether';
    is format_units('1500000000000000000', ETHER), '1.5',   'format 1.5 ether';
    is format_units('1000000000000000',    ETHER), '0.001', 'format 0.001 ether';
    is format_units('20000000000',         GWEI),  '20',    'format 20 gwei';
};

subtest 'format_units with strings' => sub {
    is format_units('1',                   'wei'),    '1',    'format 1 wei string';
    is format_units('1000000000',          'gwei'),   '1',    'format 1 gwei string';
    is format_units('1000000000000000000', 'ether'),  '1',    'format 1 ether string';
    is format_units('5250000000000000',    'finney'), '5.25', 'format 5.25 finney';
};

subtest 'format_units with numeric decimals' => sub {
    is format_units('1',       0), '1',   'format with 0 decimals';
    is format_units('1000000', 6), '1',   'format with 6 decimals';
    is format_units('25000',   4), '2.5', 'format 2.5 with 4 decimals';
};

subtest 'round trip conversions' => sub {
    my @test_values = ('1', '1.5', '0.001', '20', '5.25');
    my @test_units  = (ETHER, GWEI, 'finney', 6);

    for my $value (@test_values) {
        for my $unit (@test_units) {
            my $parsed    = parse_units($value, $unit);
            my $formatted = format_units($parsed, $unit);
            is $formatted, $value, "round trip: $value -> $parsed -> $formatted";
        }
    }
};

subtest 'error conditions' => sub {
    # Invalid numbers for parse_units
    eval { parse_units('abc', ETHER) };
    like($@, qr/Invalid number format/, 'parse_units dies on invalid number');

    eval { format_units('abc', ETHER) };
    like($@, qr/Invalid number format/, 'format_units dies on invalid number');

    # Invalid units
    eval { parse_units('1', 'invalid') };
    like $@, qr/Unknown unit/, 'parse_units dies on invalid unit';

    eval { format_units('1', 'invalid') };
    like $@, qr/Unknown unit/, 'format_units dies on invalid unit';

    eval { parse_units('1', 'ethe') };
    like $@, qr/Unknown unit/, 'parse_units dies on typo unit';

    # Test with undefined values
    eval { parse_units(undef, ETHER) };
    like $@, qr/Invalid number format/, 'parse_units dies on undef value';

    eval { parse_units('1', undef) };
    like $@, qr/Unknown unit/, 'parse_units dies on undef unit';

    # Test empty string
    eval { parse_units('', ETHER) };
    like $@, qr/Invalid number format/, 'parse_units dies on empty string';

    # Test non-numeric strings
    eval { parse_units('not-a-number', GWEI) };
    like $@, qr/Invalid number format/, 'parse_units dies on text input';

    eval { format_units('not-a-number', GWEI) };
    like $@, qr/Invalid number format/, 'format_units dies on text input';
};

# Test case sensitivity
subtest 'case sensitivity' => sub {
    is parse_units('1', 'ETHER'), parse_units('1', 'ether'), 'case insensitive units';
    is parse_units('1', 'Gwei'),  parse_units('1', 'gwei'),  'mixed case units';
    is format_units('1000000000000000000', 'ETH'), '1', 'ETH alias works';
};

# Test edge cases
subtest 'edge cases' => sub {
    is parse_units('0', ETHER),  '0', 'parse zero';
    is format_units('0', ETHER), '0', 'format zero';

    # Very large numbers
    my $large = '999999999999999999999999999999';
    is parse_units('1', ETHER),     '1000000000000000000',             'parse returns integer string';
    is format_units($large, ETHER), '999999999999.999999999999999999', 'format handles large numbers';
};

done_testing();
