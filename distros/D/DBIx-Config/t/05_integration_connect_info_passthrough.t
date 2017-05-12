#!/usr/bin/perl
use warnings;
use strict;
use DBIx::Config;
use Test::More;
use DBI;

my $dbh = DBI->connect( 
    DBIx::Config->new->connect_info("dbi:SQLite:dbname=:memory:" ) 
);

ok my $sth = $dbh->prepare( "CREATE TABLE hash( key string, value string )" );
ok $sth->execute();

ok $sth = $dbh->prepare( "INSERT INTO hash VALUES( ?, ? )" );
ok $sth->execute( "Hello", "World" );

ok $sth = $dbh->prepare( "SELECT value FROM hash WHERE key = ?" );
ok $sth->execute( "Hello" );

is( ($sth->fetchrow_array)[0], "World" );

done_testing;
