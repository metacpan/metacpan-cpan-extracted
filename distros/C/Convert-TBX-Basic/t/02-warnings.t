# test errors/warnings during TBX-Basic conversion

use strict;
use warnings;
use Test::More;
plan tests => 2;
use Test::NoWarnings;
use Test::Exception;
use Convert::TBX::Basic 'basic2min';

subtest 'croak with improper usage' => sub {
    plan tests => 3;
    # test with providing no args, just the data, and
    # just the data and source language. These should all
    # die since 3 args are required.
    my @args1 = qw(path/to/file EN);
    my @args2;
    for(0 .. 2){
        throws_ok (
            sub { basic2min(@args2); },
            qr/Usage: basic2min\(data, source-language, target-language\)/i,
            'croaks without language parameters'
        );
        push @args2, shift @args1;
    }
};
