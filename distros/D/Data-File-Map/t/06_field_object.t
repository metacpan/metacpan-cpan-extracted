#!/usr/bin/perl -w
use strict;
use warnings;


use Test::More tests => 4;


use_ok('Data::File::Map::Field');

my $field = Data::File::Map::Field->new;
isa_ok $field, 'Data::File::Map::Field';



use Data::File::Map;

my $map = Data::File::Map->new_from_file( 't/data/text.xml' );

my @fields = $map->fields(1);

isa_ok ( $fields[0], 'Data::File::Map::Field' );

ok ( $map->get_field('id'), 'retrieved id field');



#print $_, ': ', $fields[0]->$_, "\n" for qw(name position width label);