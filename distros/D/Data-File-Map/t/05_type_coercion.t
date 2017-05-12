#!/usr/bin/perl -w
use strict;

package Foo::Bar;

use Moose;
use Data::File::Map;

has 'map' => (
    is => 'rw',
    isa => 'Data::File::Map',
    coerce => 1,
);


use Test::More tests => 1;

my $foo = Foo::Bar->new( map => 't/data/csv.xml' );
isa_ok $foo->map, 'Data::File::Map';


