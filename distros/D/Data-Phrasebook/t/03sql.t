#!/usr/bin/perl -w
use strict;
use lib 't/lib';
use vars qw( $class );
use BookDB;

use Test::More tests => 17;

# ------------------------------------------------------------------------

$class = 'Data::Phrasebook';
use_ok $class;

my $file = 't/03phrases.txt';

# ------------------------------------------------------------------------

{
    my $dbh = BookDB->new();

    my $obj = $class->new(
        class => 'SQL',
        file => $file,
        dbh => $dbh,
    );
    isa_ok( $obj => 'Data::Phrasebook::SQL' );

    $obj->delimiters( qr{:(\w+)} );
    my $author = 'Lance Parkin';
    my $q = $obj->query( 'find_author', {
            author => \$author,
        });
    isa_ok( $q => 'Data::Phrasebook::SQL::Query' );

    $q->prepare();

    {
        my $count = 0;
        $q->execute();
        while ( my $row = $q->fetchrow_hashref )
        {
            $count++ if $row->{author} eq $author;
        }
        is( $count => 7, "7 Parkins" );
        $q->finish();
    }

    {
        my $count = 0;
        $author = 'Paul Magrs';
        $q->execute();
        while ( my $row = $q->fetchrow_hashref )
        {
            $count++ if $row->{author} eq $author;
        }
        is( $count => 3, "3 Magrs" );
        $q->finish();
    }

    {
        my $count = 0;
        $q->execute( author => 'Lawrence Miles' );
        while ( my $row = $q->fetchrow_hashref )
        {
            $count++ if $row->{author} eq 'Lawrence Miles';
        }
        is( $count => 7, "7 Miles" );
        $q->finish();
    }
}

{
    my $dbh = BookDB->new();

    my $obj = $class->new(
        class => 'SQL',
        file => $file,
        dbh => $dbh,
    );
    my $author = 'Lance Parkin';
    my $q = $obj->query( 'find_author' );
    isa_ok( $q => 'Data::Phrasebook::SQL::Query' );

    {
        my $count = 0;
        $q->execute( author => 'Lawrence Miles' );
        while ( my $row = $q->fetchrow_hashref )
        {
            $count++ if $row->{author} eq 'Lawrence Miles';
        }
        is( $count => 7, "7 more Miles" );
    }
}

{
    my $dbh = BookDB->new();

    my $obj = $class->new(
        class => 'SQL',
        file => $file,
        dbh => $dbh,
    );

    my $author = 'Lance Parkin';
    my $q = $obj->query( 'find_fields',
		'replace' => { 'fields' => 'class,title,author' },
		'bind'    => { 'author' => $author }
		);
    isa_ok( $q => 'Data::Phrasebook::SQL::Query' );

    $q->prepare();

    {
        my $count = 0;
        $q->execute();
        while ( my $row = $q->fetchrow_hashref )
        {
            $count++ if $row->{author} eq $author;
        }
        is( $count => 7, "7 Parkins" );
        $q->finish();
    }

    {
        my $count = 0;
        $q->execute( author => 'Lawrence Miles' );
        while ( my $row = $q->fetchrow_hashref )
        {
            $count++ if $row->{author} eq 'Lawrence Miles';
        }
        is( $count => 7, "7 more Miles" );
		$q->sth->finish;
    }
}

{
    my $dbh = BookDB->new();

    my $obj = $class->new(
        class => 'SQL',
        file => $file,
        dbh => $dbh,
    );

    eval { my $q = $obj->query( 'notfound' ); };
    like( $@ => qr/No mapping/ );
}

{
	my $dbh = BookDB->new();

    my $obj = $class->new(
        class => 'SQL',
        file => $file,
    );

    my $author = 'Lance Parkin';
    my $q = $obj->query( 'find_fields',
		'replace' => { 'fields' => 'author' },
		'bind'    => { 'author' => $author }
		);

    eval { $q->prepare(); };
	like( $@, qr//, "Can't prepare without a DB connection" );
	$q->dbh($dbh);
    eval { $q->prepare(); };
	is( $@, '', "Can prepare with a DB connection" );

	my $sql = 'select class,title,author from books where author = ?';
	my $old = $q->sql;
	my $new = $q->sql($sql);
	is( $new, $sql, "New is changed" );
	isnt( $new, $old, "New isnt old" );

    $q->prepare();

	{
        my $count = 0;
        $q->execute();
        while ( my $row = $q->fetchrow_hashref )
        {
            $count++ if $row->{author} eq $author;
        }
        is( $count => 7, "7 more Parkins" );
		$q->sth->finish;
    }
}
