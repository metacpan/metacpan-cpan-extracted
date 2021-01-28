#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use CellBIS::SQL::Abstract;

my $sql_abstract = CellBIS::SQL::Abstract->new(db_type => 'sqlite');
my $create_table = '';
my $to_compare
  = 'CREATE TABLE IF NOT EXISTS company( '
  . 'id_company INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, '
  . 'id_company_users INTEGER NOT NULL, '
  . 'company_name VARCHAR NOT NULL, '
  . 'CONSTRAINT user_company_fk FOREIGN KEY (id_company_users) REFERENCES users (id) '
  . 'ON DELETE CASCADE ON UPDATE CASCADE )';

my $table_name = 'company';
my $col_list   = ['id_company', 'id_company_users', 'company_name',];
my $col_attr   = {
  'id_company' =>
    {type => {name => 'integer'}, is_primarykey => 1, is_autoincre => 1,},
  'id_company_users' => {type => {name => 'integer'}, is_null => 0,},
  'company_name' => {type => {name => 'varchar', size => '200',}, is_null => 0,}
};
my $table_attr = {
  fk => {
    name         => 'user_company_fk',
    col_name     => 'id_company_users',
    table_target => 'users',
    col_target   => 'id',
    attr         => {onupdate => 'cascade', ondelete => 'cascade'}
  }
};
$create_table
  = $sql_abstract->create_table($table_name, $col_list, $col_attr, $table_attr);
my $on_liner = $sql_abstract->to_one_liner($create_table);

is($on_liner, $to_compare, "Query Table has created : \n$create_table\n");

done_testing();

