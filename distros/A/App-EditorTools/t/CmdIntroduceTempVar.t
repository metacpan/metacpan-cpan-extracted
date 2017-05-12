#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 2;
use Test::Differences;

use lib 't/lib';
use AETest;

{
    no warnings qw(qw); # Turn off warnings about comma being used as a sep

    my $return =
      AETest->test( [qw{introducetemporaryvariable -s 1,13 -e 1,21 -v foo}],
        <<'CODE' );
my $x = 1 + (10 / 12) + 15;
my $x = 3 + (10 / 12) + 17;
CODE
    like( $return->stdout, qr/my \$foo = \(10 \/ 12\)/, 'IntroduceTempVar' );
    is( $return->error, undef, '... no error' );
}

