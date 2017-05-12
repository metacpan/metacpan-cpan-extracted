#  Copyright (c) 2009 David Caldwell,  All Rights Reserved. -*- cperl -*-

use Test::More;
use Test::Script::Run;

my @test = ([ '1+3',     '4',             'simple addition'],
            [ '1/4+1/5', '9/20',          'bigrat'],
            [ '1m',      '1048576',       'power of 2 units'],
            [ '1m',      '1,048,576',     'comma output'],
            [ '1m',      '1MB',           'Exact power of 2 output units'],
            [ '1mb',     '1MB',           'Alternate power of two units 1'],
            [ '1M',      '1MB',           'Alternate power of two units 2'],
            [ '1MB',     '1MB',           'Alternate power of two units 3'],
            [ '1m+1',    '1.00MB',        'Inexact power of 2 output units 1'],
            [ '1m+512k', '1.50MB',        'Inexact power of 2 output units 2'],
            [ '1.5m',    '1.50MB',        'Inexact power of 2 output units 3'],
            [ '10000',   '0x2710',        'hex output'],
            [ '10000',   '023420',        'octal output'],
            [ '5+3*20',  'A',             'ascii output'],
            [ '1<<40',   '0x10000000000', 'bigint'],
            [ '1<<70',   '1ZB',           'Really bigint'],
            [ '1<<80',   '1YB',           'Really really bigint'],
            [ '1<<150',  '1.18e\+21YB',   'Really really really bigint'],
           );

plan tests => scalar @test;

# Test::Script::Run wants the exes in bin/ or t/bin/
mkdir 't/bin';
symlink '../../pc', 't/bin/pc';

for (@test) {
    run_output_matches('pc', [$_->[0]], [qr/\b$_->[1]\b/], [''], $_->[2])
}
