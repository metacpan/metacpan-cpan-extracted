#!/usr/local/bin/perl

use rlib qw(../lib ../blib/lib ../blib/arch);
use feature ":5.10";
use Config::UCL;
use JSON::PP;

my $hash = ucl_load('var1 = "${var1}"; var2 = "$var2"',
    {
        ucl_parser_register_variables => [ var1 => 'val1', val2 => 'val2' ],
    }
);
say JSON::PP->new->canonical->encode($hash);
