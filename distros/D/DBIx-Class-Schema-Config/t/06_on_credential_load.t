#!/usr/bin/perl
use warnings;
use strict;
use Test::More;
use lib 't/lib'; # Tests above t/
use lib 'lib';   # Tests inside t/
use DBIx::Class::Schema::Config::Plugin;
use Data::Dumper;

# Using a config file, with a plugin changing the DSN.
ok my $Schema = DBIx::Class::Schema::Config::Plugin->connect('PLUGIN', { dbname => ':memory:' }),
    "Connection to a plugin-modified schema works.";

my $expect = [
    {
        password => '', 
        user => '', 
        dsn => 'dbi:SQLite:dbname=:memory:'
    }
];

is_deeply $Schema->storage->connect_info, $expect, "Expected schema changes happened."; 

done_testing;
