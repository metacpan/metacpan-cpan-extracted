#!/usr/bin/perl
use warnings;
use strict;
use Test::More;
use lib 't/lib'; # Tests above t/
use lib 'lib';   # Tests inside t/
use DBIx::Class::Schema::Config::ConfigFiles;

# Using a config file.
ok my $Schema1 = DBIx::Class::Schema::Config::ConfigFiles->connect('TEST'),
    "Can connect to the Test Schema.";

ok $Schema1->storage->dbh->do( "CREATE TABLE hash ( key text, value text )" ),
    "Can create table against the raw dbh.";

ok $Schema1->resultset('Hash')->create( { key => "Dr", value => "Spaceman" } ),
    "Can write to the Test Schema.";

is $Schema1->resultset('Hash')->find( { key => 'Dr' }, { key => 'key_unique' } )->value, 'Spaceman',
    "Can read from the Test Schema.";

# Pass through of array.
ok my $Schema2 = DBIx::Class::Schema::Config::ConfigFiles->connect('dbi:SQLite:dbname=:memory:', '', ''),
    "Can connect to the Test Schema.";

ok $Schema2->storage->dbh->do( "CREATE TABLE hash ( key text, value text )" ),
    "Can create table against the raw dbh.";

ok $Schema2->resultset('Hash')->create( { key => "Dr", value => "Spaceman" } ),
    "Can write to the Test Schema.";

is $Schema2->resultset('Hash')->find( { key => 'Dr' }, { key => 'key_unique' } )->value, 'Spaceman',
    "Can read from the Test Schema.";
    
# Pass through of hash
ok my $Schema3 = DBIx::Class::Schema::Config::ConfigFiles->connect({ dsn => 'dbi:SQLite:dbname=:memory:' }),
    "Can connect to the Test Schema.";

ok $Schema3->storage->dbh->do( "CREATE TABLE hash ( key text, value text )" ),
    "Can create table against the raw dbh.";

ok $Schema3->resultset('Hash')->create( { key => "Dr", value => "Spaceman" } ),
    "Can write to the Test Schema.";

is $Schema3->resultset('Hash')->find( { key => 'Dr' }, { key => 'key_unique' } )->value, 'Spaceman',
    "Can read from the Test Schema.";
    
    
    
    
    
done_testing;
