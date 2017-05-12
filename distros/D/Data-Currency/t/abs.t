#!/usr/bin/env perl
use strict;
use warnings;
use Data::Currency;
use Test::More tests => 4;

{
    my $value = abs( Data::Currency->new( -1.2, 'USD' ) );
    is $value->value, 1.2,   '-1.2 abs value';
    is $value->code,  'USD', '-1.2 abs code';
}

{
    my $value = abs( Data::Currency->new( 1.2, 'USD' ) );
    is $value->value, 1.2,   '1.2 abs value';
    is $value->code,  'USD', '1.2 abs code';
}
