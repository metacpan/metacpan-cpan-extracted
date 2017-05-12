#!/usr/bin/perl -w
use strict;
use lib 't/lib';
use vars qw( $class );
use BookDB;

use Test::More tests => 5;

# ------------------------------------------------------------------------

$class = 'Data::Phrasebook';
use_ok $class;

my $file = 't/02phrases.txt';

# ------------------------------------------------------------------------

{
    my $dbh = BookDB->new();

    my $obj = $class->new(
        class => 'SQL',
        file => $file,
        dbh => $dbh,
    );

    my ($count) = $obj
        ->query( 'count_author', {
                author => 'Lawrence Miles'
            } )
        ->fetchrow_array;

    is( $count => 7, "Quick Miles" );
}

{
    my $dbh = BookDB->new();

    my $obj = $class->new(
        class => 'SQL',
        file => $file,
        dbh => $dbh,
    );

    my $author = 'Lawrence Miles';
    my $q = $obj->query( 'find_author' );
    isa_ok( $q => 'Data::Phrasebook::SQL::Query' );

    # Slow
    {
        my $count = 0;
        $q->execute( author => $author );
        while ( my $row = $q->fetchrow_hashref )
        {
            $count++ if $row->{author} eq $author;
        }
        is( $count => 7, "row by row Miles" );
        $q->finish;
    }

    # fetchall_arrayref
    {
        my $count = 0;
        $q->execute( author => $author );
        my $r = $q->fetchall_arrayref;
        is ( scalar @$r => 7, "fetchall Miles" );
        $q->finish;
    }
}
