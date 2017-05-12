# Author: I.Plisco
# Aim: Tests SQL composition.
# -*- perl -*-


use Test::More tests => 11;

use DBIx::Composer;

my $cmd = DBIx::Composer->new ();

# Test that anything works
$cmd->{table} = 'table1';
is($cmd->{table}, 'table1', 'set one field');

# Compose select
$cmd->{table} = 'table1';
$cmd->{fields} = "f1, f2, f3+f4";
$cmd->{where} = "where a=b";
$cmd->{limit} = "limit 10";
$cmd->{order} = "order by f1 desc";
$cmd->{group} = "group by f2";
is($cmd->compose_select, 
  "select f1, f2, f3+f4 from table1 where a=b group by f2 order by f1 desc limit 10",
  'compose_select');

# Compose insert with $fields
$cmd->{fields} = "f1, f2";
$cmd->{values} = "1,2";
is($cmd->compose_insert, 
  "insert into table1 (f1, f2) values (1,2)",
  'compose_insert');

# Compose insert without $fields
$cmd->{fields} = "";
$cmd->{values} = "1,2";
is($cmd->compose_insert, 
  "insert into table1 values (1,2)",
  'compose_insert without fields');

# Compose replace with $fields
$cmd->{fields} = "f1, f2";
$cmd->{values} = "1,2";
is($cmd->compose_replace, 
  "replace into table1 (f1, f2) values (1,2)",
  'compose_replace');

# Compose replace without $fields
$cmd->{fields} = "";
$cmd->{values} = "1,2";
is($cmd->compose_replace, 
  "replace into table1 values (1,2)",
  'compose_replace without fields');

# Compose replace with $set
$cmd->{fields} = "";
$cmd->{values} = "";
$cmd->{set} = "set f1=1, f2=2";
is($cmd->compose_replace, 
  "replace into table1 set f1=1, f2=2");


# Compose delete with $where
$cmd->{where} = "where a=b";
is($cmd->compose_delete, 
  "delete from table1 where a=b",
  'compose_delete');

# Compose delete without $where
$cmd->{where} = "";
is($cmd->compose_delete, 
  "delete from table1",
  'compose_delete without where');


# Compose update with $where
$cmd->{where} = "where a=b";
$cmd->{set} = "set a = c+1";
is($cmd->compose_update, 
  "update table1 set a = c+1 where a=b",
  'compose_update');

# Compose update without $where
$cmd->{where} = "";
is($cmd->compose_update, 
  "update table1 set a = c+1",
  'compose_update without where');

