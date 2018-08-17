#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use CellBIS::SQL::Abstract;

my $sql_abstract = CellBIS::SQL::Abstract->new(db_type => 'sqlite');
my $create_table = '';
my $to_compare
  = 'CREATE TABLE IF NOT EXISTS users( '
  . 'id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, '
  . 'first_name VARCHAR NOT NULL, '
  . 'last_name VARCHAR NOT NULL, '
  . 'other_col_name VARCHAR NOT NULL )';

my $table_name = 'users';
my $col_list   = ['id', 'first_name', 'last_name', 'other_col_name'];
my $col_attr   = {
  'id' => {type => {name => 'integer'}, is_primarykey => 1, is_autoincre => 1,},
  'first_name'     => {type => {name => 'varchar', size => 50,}, is_null => 0,},
  'last_name'      => {type => {name => 'varchar', size => 50,}, is_null => 0,},
  'other_col_name' => {type => {name => 'varchar', size => 60,}, is_null => 0,}
};
my $table_attr = {engine => 'innodb',};
$create_table
  = $sql_abstract->create_table($table_name, $col_list, $col_attr, $table_attr);
my $on_liner = $sql_abstract->to_one_liner($create_table);

is($on_liner, $to_compare, "Query Table has created : \n$create_table\n");

done_testing();
