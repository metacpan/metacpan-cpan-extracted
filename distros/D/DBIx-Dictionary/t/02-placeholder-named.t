#!/usr/bin/perl

use strict;
use warnings;

use DBIx::Dictionary;
use Test::More qw(no_plan);

my $dbname   = '/tmp/dbix-dictionary-test.db';
my $dictfile = 't/dictionary.ini';

END {
    unlink $dbname if -f $dbname;
}

SKIP: {
    eval { require DBIx::Placeholder::Named; };

    skip "DBIx::Placeholder::Named", 2 if $@;

    my $dbh = DBIx::Dictionary->connect(
        "dbi:SQLite:dbname=$dbname",
        '', '',
        {
            PrintError         => undef,
            RaiseError         => undef,
            ShowErrorStatement => undef,
            DictionaryFile     => $dictfile,
            DictionaryName     => 'placeholder',
            RootClass          => 'DBIx::Placeholder::Named',
        }
    );
    ok($dbh);
    {
        my $query = q{THIS IS NOT A SQL QUERY};
        my $sth   = $dbh->prepare($query);
        is( $sth, undef, $query );
    }

    {
        my $query = q{CREATE TABLE test (id int, name varchar)};
        my $sth   = $dbh->prepare($query);
        ok( $sth, $query );
        my $rv = $sth->execute();
        ok( $rv, $query . ': execute()' );
    }

    {
        my $query = q{fetch_test_with_id};
        my $sth   = $dbh->prepare($query);
        ok( $sth, $query );
        my $rv = $sth->execute( { id => 1 } );
        is( $rv, '0E0' );
    }

    {
        my $query = q{insert_test};
        my $sth   = $dbh->prepare($query);
        ok( $sth, $query );
        my $rv = $sth->execute( { id => 1, name => 'Test', } );
        ok( $rv, $query . ': execute()' );

    }

    {
        my $query = q{update_test};
        my $sth   = $dbh->prepare($query);
        ok( $sth, $query );
        my $rv =
          $sth->execute( { new_id => 2, name => 'Newer test', old_id => 1 } );
        ok( $rv, $query . ': execute()' );
    }

    {
        my $query = q{delete_test};
        my $sth   = $dbh->prepare($query);
        ok( $sth, $query );
        my $rv = $sth->execute( { id => 2 } );
        ok( $rv, $query . ': execute()' );
    }

    $dbh->disconnect;

}
