use strict;
use warnings;

use DBIx::Table::TestDataGenerator;

#This is an example you can use to try out the module.
#Please add the dsn to a database of your choice as well 
#as a database username and password below and run the 
#script in the file example.sql contained in the current
#directory before running example.pl.
my $dsn = 'dbi:SQLite:dbname=';
my $user = '';
my $password = '';

my $table = 'employee';

my $generator = DBIx::Table::TestDataGenerator->new(
    dsn                   => $dsn,
    user                  => $user,
    password              => $password,    
    table                 => $table,
);

$generator->create_testdata(
    target_size               => 500,
    num_random                => 50,
    max_tree_depth            => 5,
    min_children              => 2,
    min_roots                 => 4,
    roots_have_null_parent_id => 1,
);