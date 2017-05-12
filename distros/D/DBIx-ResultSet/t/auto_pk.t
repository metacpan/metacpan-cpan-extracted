#!/usr/bin/perl -w
use strict;
use warnings;

use Test::More;
use DBIx::ResultSet::Connector;

my $connector = DBIx::ResultSet->connect( 'dbi:SQLite:dbname=t/test.db', '', '' );

$connector->run(sub{
    my ($dbh) = @_;

    $dbh->do('DROP TABLE IF EXISTS users');
    $dbh->do('CREATE TABLE users (user_id INTEGER PRIMARY KEY AUTOINCREMENT, user_name TEXT, status NUMBER)');
});

my $users = $connector->resultset('users');

$users->insert( {user_name=>'one',   status=>1} );
is( $users->auto_pk(), 1, 'auto PK 1' );

$users->insert( {user_name=>'two',   status=>0} );
is( $users->auto_pk(), 2, 'auto PK 2' );

$users->insert( {user_name=>'three', status=>1} );
is( $users->auto_pk(), 3, 'auto PK 3' );

done_testing;
