#!/usr/bin/perl -w
package main;

use strict;
use warnings;

use Test::More;
use t::lib::Utils;
use t::app::Main;
use Data::Dumper 'Dumper';

plan tests => 8;

my $schema = t::app::Main->connect('dbi:SQLite:t/example.db');
$schema->deploy({ add_drop_table => 1 });
populate_database($schema);

my $mj = $schema->resultset('Artist')->find(1);

is $mj->artist_attribute->year_old, 56, "we can access to year_old artist_attribute from artist object";


my $cd = {
  'name' => $mj->name,
  'id' => $mj->id
};
my $cdwa = {
  'name' => $mj->name,
  'id' => $mj->id,
  'year_old' => $mj->artist_attribute->year_old,
};

is_deeply $mj->get_column_data, $cd, "get_column_data return column data of artist";
is_deeply $mj->get_column_data_with_attribute, $cdwa, "get_column_data_with_attribute return column data of artist and artist attribute";

# test deprecated function continue to work
is_deeply $mj->get_column_data_with_attribute, $mj->columns_data_with_attribute, "columns_data_with_attribute continue to work";

$mj->update({year_old => "57", name => "Michael Jackson the king of the pop"});

my $n1 = $schema->resultset('Artist')->find(1);

is $n1->name, "Michael Jackson the king of the pop", "year_old artist_attribute is updated";
is $n1->artist_attribute->year_old, 57, "year_old artist_attribute is updated";

my $rh = {name => "Janet Jackson", year_old => 48};
$rh = $schema->class('Artist')->prepare_params_with_attribute($rh);
my $jj = $schema->resultset('Artist')->create($rh);

my $n2 = $schema->resultset('Artist')->single({name => "Janet Jackson"});

is $n2->name, "Janet Jackson", "year_old artist_attribute is updated";
is $n2->artist_attribute->year_old, 48, "year_old artist_attribute is set when artist is created";

1;
