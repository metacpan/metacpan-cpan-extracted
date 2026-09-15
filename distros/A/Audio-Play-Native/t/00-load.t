#!/usr/bin/env perl

use 5.008001;
use strict;
use warnings;
use Test::More tests => 2;

use lib 'lib';
use lib '../lib';
use lib 'Audio-Play-Native/lib';

use Audio::Play::Native;

ok( $Audio::Play::Native::VERSION, 'Audio::Play::Native version defined' );
ok(
    defined Audio::Play::Native->detected_backend,
    'detected_backend returns a string'
);

1;
