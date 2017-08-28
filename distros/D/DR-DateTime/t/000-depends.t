#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib t/lib);

use Test::More tests    => 4;
use Encode qw(decode encode);


BEGIN {
    require_ok 'Time::Local';
    require_ok 'Time::Zone';
    require_ok 'POSIX';
    require_ok 'Data::Dumper';
}


