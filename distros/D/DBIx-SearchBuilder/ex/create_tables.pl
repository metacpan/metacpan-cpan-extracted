#!/usr/bin/perl

use strict;
use warnings;

# Note: this script does not actually *create* the tables;
# however, it needs to connect to the database in order to
# get the specific capabilities of your database (like type info).
# CHANGE THIS TO FIT YOUR DATABASE:
my @CONNECT_ARGS = (
  Driver => 'Pg',
  Database => 'test',
  Host => 'localhost',
  User => 'postgres',
  Password => '',
);

use DBIx::SearchBuilder::Handle;
use DBIx::SearchBuilder::SchemaGenerator;

my $BaseClass;

BEGIN {
  unless (@ARGV) {
    die <<USAGE;
usage: $0 Base::Class [libpath ...]
  This script will search \@INC (with the given paths added
  to its beginning) for all classes beginning with Base::Class::,
  which should be subclasses of DBIx::SearchBuilder::Record implementing
  Schema and Table.  It prints SQL to generate tables standard output.
  
  While it does not actually create the tables, it needs to connect to your
  database (for now, must be Pg or maybe mysql) in order to discover specific
  capabilities of the target database.  You should edit \@CONNECT_ARGS in this
  script to provide an appropriate database driver, database name, host, user, 
  and password.
USAGE
  }
  $BaseClass = shift;
  unshift @INC, @ARGV;
}  

use Module::Pluggable search_path => $BaseClass, sub_name => 'models', instantiate => 'new';

my $handle = DBIx::SearchBuilder::Handle->new;

$handle->Connect( @CONNECT_ARGS );
	
my $SG = DBIx::SearchBuilder::SchemaGenerator->new($handle);

die "Couldn't make SchemaGenerator" unless $SG;

for my $model (__PACKAGE__->models) {
  my $ret = $SG->AddModel($model);
  $ret or die "couldn't add model $model: ".$ret->error_message;
}

print $SG->CreateTableSQLText;
