#!perl

use v5.42.0;

use strict;
use warnings;

use Test2::V1 qw< is >;
T2->plan(2);

use ExtUtils::Manifest qw< manicheck filecheck >;

is(
    [ manicheck() ], [],
    'manicheck() - missing files',
);

is(
    [ filecheck() ], [],
    'filecheck() - extra files',
);
