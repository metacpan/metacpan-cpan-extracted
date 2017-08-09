#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib t/lib);
use lib qw(blib/lib blib/arch ../blib/lib ../blib/arch);

use Test::More tests    => 2;
use Encode qw(decode encode);


BEGIN {
    use_ok 'DR::R';
}

is DR::R::_ping(), 'pong', 'ping';
