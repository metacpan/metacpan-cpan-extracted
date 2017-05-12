#!/usr/bin/perl -w

# ------------------------------------------------------------------------------
#
# ------------------------------------------------------------------------------

use strict;
use warnings;

use Test::More;

use FindBin qw($Bin);
use lib ("$Bin/../lib");

use Data::Password::Entropy;

&main();
# ------------------------------------------------------------------------------
sub main
{
    my %pass = (
        ''                  => 0,
        '1'                 => 3,
        'a'                 => 4,
        'a' x 100           => 9,
        '7s'                => 10,
        'abc'               => 11,
        '21920392'          => 20,
        '_S?I'              => 23,
        'pass123'           => 31,
        'ZMHZ0d'            => 32,
        'QGfmyw'            => 34,
        '5dAekE'            => 35,
        '1%Tp_\'oP[viSm&IdGexz' => 128,
        'g9Hi;4z/X+%nHx?5__v"=fa4"8Tzs>nW:4\'<GE)Qc"}U$@2WN=JQ!G,[7ryVS-3p' => 353,
    );

    plan(tests => scalar(keys(%pass)));

    for my $k (sort(keys(%pass))) {
        is(password_entropy($k), $pass{$k}, "Password \"$k\"");
    }
}
# ------------------------------------------------------------------------------
1;
