#!/usr/bin/env perl
use strict;
use warnings;
use Data::Currency;
use Test::More tests => 4;

{
    my $value = int( Data::Currency->new( -1.5, 'USD' ) );
    is $value->value, -1,    '-1.5 int value';
    is $value->code,  'USD', '-1.5 int code';
}

{
    my $value = int( Data::Currency->new( 1.999999, 'USD' ) );
    is $value->value, 1,     '1.99999 int value';
    is $value->code,  'USD', '1.99999 int code';
}

