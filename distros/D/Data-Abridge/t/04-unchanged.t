#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 1;
use Data::Dumper;


use Data::Abridge qw( abridge_recursive abridge_item );

my $foo = bless [ foo => { Bar => [qw( a b c d )] }  ], 'Roach';

my $bar = { foo => $foo };
use Storable 'dclone';
my $baz = dclone $bar;


print Dumper $bar;

abridge_recursive( $bar );

print Dumper $bar;

is_deeply( $bar, $baz, 'DS is unchanged' );
