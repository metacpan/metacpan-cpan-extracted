#!/usr/bin/perl
use warnings;
use strict;
use DBIx::Config;
use Test::More;

my $dbh = DBIx::Config
    ->new( { 
            config_paths => [ "etc/config", "t/etc/config" ], 
            filter_loaded_credentials => sub {
                my ( $self, $loaded_credentials, $source ) = @_;
                $loaded_credentials->{dsn} = 
                    sprintf( $loaded_credentials->{dsn}, $source->{hostname} );
                return $loaded_credentials;
            },
        }
    )
    ->connect( "PLUGIN", { hostname => ":memory:" } );

ok my $sth = $dbh->prepare( "CREATE TABLE hash( key string, value string )" );
   ok $sth->execute();

   ok $sth = $dbh->prepare( "INSERT INTO hash VALUES( ?, ? )" );
   ok $sth->execute( "Hello", "World" );
   
   ok $sth = $dbh->prepare( "SELECT value FROM hash WHERE key = ?" );
   ok $sth->execute( "Hello" );

   is( ($sth->fetchrow_array)[0], "World" );


# Can Manually Connect Too?
$dbh = DBIx::Config->connect( "dbi:SQLite:dbname=:memory:" );

ok $sth = $dbh->prepare( "CREATE TABLE hash( key string, value string )" );
ok $sth->execute();

ok $sth = $dbh->prepare( "INSERT INTO hash VALUES( ?, ? )" );
ok $sth->execute( "Hello", "World" );

ok $sth = $dbh->prepare( "SELECT value FROM hash WHERE key = ?" );
ok $sth->execute( "Hello" );

is( ($sth->fetchrow_array)[0], "World" );


done_testing;
