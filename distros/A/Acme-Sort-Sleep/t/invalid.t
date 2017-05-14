#!/usr/bin/env perl

use strict;
use warnings;

use Acme::Sort::Sleep qw( sleepsort );
use Test::More;
use Test::Exception;

my $error = qr/Only positive numbers accepted./;

my @undefined   = ( undef );
my @negative    = ( -1 );
my @non_numeric = ( 'z' );

throws_ok { sleepsort( @undefined    ) } $error, 'undef';
throws_ok { sleepsort( @negative     ) } $error, 'negative number';
throws_ok { sleepsort( @non_numeric  ) } $error, 'non-numeric value';
    
done_testing;
