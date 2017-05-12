#!/usr/bin/perl
use warnings;
use strict;
use Test::More;
use lib 't/lib'; # Tests above t/
use lib 'lib';   # Tests inside t/
use DBIx::Class::Schema::Config::Test;

# Using a config file.
my $expected_config = [
    {
        't/etc/config.perl' => {
            'TEST' => {
                'password' => '',
                'dsn' => 'dbi:SQLite:dbname=:memory:',
                'user' => ''
            },
            'PLUGIN' => {
                'password' => '',
                'dsn' => 'dbi:SQLite:dbname=%s',
               'user' => ''
            }
        }
    }
];

is_deeply(DBIx::Class::Schema::Config::Test->config, $expected_config, 
    'config from class accessor matches as expected - loaded before connect');

ok my $Schema1 = DBIx::Class::Schema::Config::Test->connect('TEST'),
    "Can connect to the Test Schema.";

ok $Schema1->storage->dbh->do( "CREATE TABLE hash ( key text, value text )" ),
    "Can create table against the raw dbh.";

ok $Schema1->resultset('Hash')->create( { key => "Dr", value => "Spaceman" } ),
    "Can write to the Test Schema.";

is $Schema1->resultset('Hash')->find( { key => 'Dr' }, { key => 'key_unique' } )->value, 'Spaceman',
    "Can read from the Test Schema.";

# Pass through of array.
ok my $Schema2 = DBIx::Class::Schema::Config::Test->connect('dbi:SQLite:dbname=:memory:', '', ''),
    "Can connect to the Test Schema.";

ok $Schema2->storage->dbh->do( "CREATE TABLE hash ( key text, value text )" ),
    "Can create table against the raw dbh.";

ok $Schema2->resultset('Hash')->create( { key => "Dr", value => "Spaceman" } ),
    "Can write to the Test Schema.";

is $Schema2->resultset('Hash')->find( { key => 'Dr' }, { key => 'key_unique' } )->value, 'Spaceman',
    "Can read from the Test Schema.";
    
# Pass through of hash
ok my $Schema3 = DBIx::Class::Schema::Config::Test->connect({ dsn => 'dbi:SQLite:dbname=:memory:' }),
    "Can connect to the Test Schema.";

ok $Schema3->storage->dbh->do( "CREATE TABLE hash ( key text, value text )" ),
    "Can create table against the raw dbh.";

ok $Schema3->resultset('Hash')->create( { key => "Dr", value => "Spaceman" } ),
    "Can write to the Test Schema.";

is $Schema3->resultset('Hash')->find( { key => 'Dr' }, { key => 'key_unique' } )->value, 'Spaceman',
    "Can read from the Test Schema.";
    
    
# Pass through of code reference.
ok my $Schema4 = DBIx::Class::Schema::Config::Test->connect(
        sub { DBI->connect( 'dbi:SQLite:dbname=:memory:', undef, undef, { RaiseError => 1 } ) } 
    ), "Can connect to the Test Schema.";

ok $Schema4->storage->dbh->do( "CREATE TABLE hash ( key text, value text )" ),
    "Can create table against the raw dbh.";

ok $Schema4->resultset('Hash')->create( { key => "Dr", value => "Spaceman" } ),
    "Can write to the Test Schema.";

is $Schema4->resultset('Hash')->find( { key => 'Dr' }, { key => 'key_unique' } )->value, 'Spaceman',
    "Can read from the Test Schema.";
    
# dbh_maker functions as one would expect.
ok my $Schema5 = DBIx::Class::Schema::Config::Test->connect({
        dbh_maker => sub {
            DBI->connect( 'dbi:SQLite:dbname=:memory:', undef, undef, { RaiseError => 1 } )
        }, 
    }), "Can connect to the Test Schema.";

ok $Schema5->storage->dbh->do( "CREATE TABLE hash ( key text, value text )" ),
    "Can create table against the raw dbh.";

ok $Schema5->resultset('Hash')->create( { key => "Dr", value => "Spaceman" } ),
    "Can write to the Test Schema.";

is $Schema5->resultset('Hash')->find( { key => 'Dr' }, { key => 'key_unique' } )->value, 'Spaceman',
    "Can read from the Test Schema.";
    
    
done_testing;
