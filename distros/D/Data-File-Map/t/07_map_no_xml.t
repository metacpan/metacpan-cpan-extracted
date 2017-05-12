#!/usr/bin/perl -w
use strict;


use Test::More tests => 5;


use_ok 'Data::File::Map';


my $map = Data::File::Map->new;
isa_ok $map, 'Data::File::Map';

$map->set_format('csv');
is $map->format, 'csv', 'format set to csv';

$map->set_separator(',');
is $map->separator, ',', 'separator set to ,';

$map->add_field( $_ ) for qw/id username email/;

is_deeply [ $map->field_names( ) ], [ qw/id username email/ ], 'set fields';

