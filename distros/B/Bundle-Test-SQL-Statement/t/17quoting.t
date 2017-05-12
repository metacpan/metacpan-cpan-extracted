#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 44;
use Data::Dumper;

# test 1
BEGIN
{
    use_ok('SQL::Statement');
    use_ok('SQL::Parser');
}
my $loaded = 1;
END { print "not ok 1\n" unless $loaded; }

my $stmt;
my $cache = {};
my $parser = SQL::Parser->new(
                               'ANSI',
                               {
                                  RaiseError => 0,
                                  PrintError => 0
                               }
                             );
for my $sql ( split( "\n", join( '', <<EOD ) ) )
CREATE TEMP TABLE "TBL WITH SPACES" (id INT, "COLUMN WITH SPACES" CHAR, "SET" INT)
INSERT INTO "TBL WITH SPACES" VALUES (1, 'foo', 1)
INSERT INTO "TBL WITH SPACES" VALUES (2, 'bar', 0)
EOD
{
    chomp $sql;
    $stmt = SQL::Statement->new( $sql, $parser );
    ok( $stmt->execute($cache), $sql );
}

    $stmt = SQL::Statement->new( q{SELECT "TBL WITH SPACES"."COLUMN WITH SPACES" FROM "TBL WITH SPACES" WHERE id=1},
                                 $parser );
    ok( !defined( $parser->structure()->{errstr} ),
        q{Parsing SELECT "TBL WITH SPACES"."COLUMN WITH SPACES" ...: } . ( $parser->structure()->{errstr} || '' ) );
    if ( defined( $parser->structure()->{errstr} ) )
    {

        #    print( Dumper( $cache ) );
        #    print( Dumper( $parser->structure() ) );
      SKIP:
        {
            skip( "Parsing select statement fails", 2 );
        }
    }
    else
    {
        my $rc = $stmt->execute($cache);
        ok( $rc == 1, 'SELECTED 1 row' );
        my $count = 0;
        while ( my $row = $stmt->fetch() )
        {

            #print( STDERR Dumper( $row ) );
            last if ($count);
            ++$count;
            ok( ( scalar( @{$row} ) == 1 ) && defined( $row->[0] ) && ( 'foo' eq $row->[0] ), q{got 'foo'} );
        }
    }

    $stmt = SQL::Statement->new( q{SELECT "COLUMN WITH SPACES" FROM "TBL WITH SPACES" WHERE id=1}, $parser );
    ok( !defined( $parser->structure()->{errstr} ),
        q{Parsing SELECT "COLUMN WITH SPACES" ...: } . ( $parser->structure()->{errstr} || '' ) );
    if ( defined( $parser->structure()->{errstr} ) )
    {

        #    print( Dumper( $cache ) );
        #    print( Dumper( $parser->structure() ) );
      SKIP:
        {
            skip( "Parsing select statement fails", 2 );
        }
    }
    else
    {
        $stmt->execute($cache);
        my $rc = $stmt->execute($cache);
        ok( $rc == 1, 'SELECTED 1 row' );
        my $count = 0;
        while ( my $row = $stmt->fetch() )
        {

            #print( Dumper( $row ) );
            last if ($count);
            ++$count;
            ok( ( scalar( @{$row} ) == 1 ) && defined( $row->[0] ) && ( 'foo' eq $row->[0] ), q{got 'foo'} );
        }
    }

    $stmt = SQL::Statement->new( q{SELECT "COLUMN WITH SPACES" AS CWS FROM "TBL WITH SPACES" WHERE id=1}, $parser );
    ok( !defined( $parser->structure()->{errstr} ),
        q{Parsing SELECT "COLUMN WITH SPACES" AS CWS ...: } . ( $parser->structure()->{errstr} || '' ) );
    if ( defined( $parser->structure()->{errstr} ) )
    {

        #    print( Dumper( $cache ) );
        #    print( Dumper( $parser->structure() ) );
      SKIP:
        {
            skip( "Parsing select statement fails", 2 );
        }
    }
    else
    {
        $stmt->execute($cache);
        my $rc = $stmt->execute($cache);
        ok( $rc == 1, 'SELECTED 1 row' );
        my $count = 0;
        while ( my $row = $stmt->fetch() )
        {

            #print( Dumper( $row ) );
            last if ($count);
            ++$count;
            ok( ( scalar( @{$row} ) == 1 ) && defined( $row->[0] ) && ( 'foo' eq $row->[0] ), q{got 'foo'} );
        }
    }

    $cache = {};
    for my $sql ( split( ';', join( '', <<EOD ) ) )
CREATE TEMP TABLE T1 (id INT, "COLUMN WITH SPACES" CHAR, "SET" INT);
INSERT INTO T1 VALUES (1, 'foo', 1);
INSERT INTO T1 VALUES (2, 'bar', 0)
EOD
    {
        $stmt = SQL::Statement->new( $sql, $parser );
        ok( $stmt->execute($cache), $sql );
    }

    $stmt = SQL::Statement->new( q{SELECT T1."COLUMN WITH SPACES" FROM T1 WHERE id=1}, $parser );
    ok( !defined( $parser->structure()->{errstr} ),
        q{Parsing SELECT T1."COLUMN WITH SPACES" ...: } . ( $parser->structure()->{errstr} || '' ) );
    if ( defined( $parser->structure()->{errstr} ) )
    {

        #    print( Dumper( $cache ) );
        #    print( Dumper( $parser->structure() ) );
      SKIP:
        {
            skip( "Parsing select statement fails", 2 );
        }
    }
    else
    {
        $stmt->execute($cache);
        my $rc = $stmt->execute($cache);
        ok( $rc == 1, 'SELECTED 1 row' );
        my $count = 0;
        while ( my $row = $stmt->fetch() )
        {

            #print( STDERR Dumper( $row ) );
            last if ($count);
            ++$count;
            ok( ( scalar( @{$row} ) == 1 ) && defined( $row->[0] ) && ( 'foo' eq $row->[0] ), q{got 'foo'} );
        }
    }

    $stmt = SQL::Statement->new( q{SELECT "COLUMN WITH SPACES" FROM T1 WHERE id=1}, $parser );
    ok( !defined( $parser->structure()->{errstr} ),
        q{Parsing SELECT "COLUMN WITH SPACES" ...: } . ( $parser->structure()->{errstr} || '' ) );
    if ( defined( $parser->structure()->{errstr} ) )
    {

        #    print( Dumper( $cache ) );
        #    print( Dumper( $parser->structure() ) );
      SKIP:
        {
            skip( "Parsing select statement fails", 2 );
        }
    }
    else
    {
        $stmt->execute($cache);
        my $rc = $stmt->execute($cache);
        ok( $rc == 1, 'SELECTED 1 row' );
        my $count = 0;
        while ( my $row = $stmt->fetch() )
        {

            #print( Dumper( $row ) );
            last if ($count);
            ++$count;
            ok( ( scalar( @{$row} ) == 1 ) && defined( $row->[0] ) && ( 'foo' eq $row->[0] ), q{got 'foo'} );
        }
    }

    $stmt = SQL::Statement->new( q{SELECT "COLUMN WITH SPACES" AS CWS FROM T1 WHERE id=1}, $parser );
    ok( !defined( $parser->structure()->{errstr} ),
        q{Parsing SELECT "COLUMN WITH SPACES" AS CWS ...: } . ( $parser->structure()->{errstr} || '' ) );
    if ( defined( $parser->structure()->{errstr} ) )
    {

        #    print( Dumper( $cache ) );
        #    print( Dumper( $parser->structure() ) );
      SKIP:
        {
            skip( "Parsing select statement fails", 2 );
        }
    }
    else
    {
        $stmt->execute($cache);
        my $rc = $stmt->execute($cache);
        ok( $rc == 1, 'SELECTED 1 row' );
        my $count = 0;
        while ( my $row = $stmt->fetch() )
        {

            #print( Dumper( $row ) );
            last if ($count);
            ++$count;
            ok( ( scalar( @{$row} ) == 1 ) && defined( $row->[0] ) && ( 'foo' eq $row->[0] ), q{got 'foo'} );
        }
    }

    $cache = {};
    for my $sql ( split( ';', join( '', <<EOD ) ) )
CREATE TEMP TABLE "TBL WITH SPACES" (id INT, CWS CHAR, "SET" INT);
INSERT INTO "TBL WITH SPACES" VALUES (1, 'foo', 1);
INSERT INTO "TBL WITH SPACES" VALUES (2, 'bar', 0)
EOD
    {
        $stmt = SQL::Statement->new( $sql, $parser );
        ok( $stmt->execute($cache), $sql );
    }

    $stmt = SQL::Statement->new( q{SELECT "TBL WITH SPACES".CWS FROM "TBL WITH SPACES" WHERE id=1}, $parser );
    ok( !defined( $parser->structure()->{errstr} ),
        q{Parsing SELECT "TBL WITH SPACES".CWS ...: } . ( $parser->structure()->{errstr} || '' ) );
    if ( defined( $parser->structure()->{errstr} ) )
    {

        #    print( Dumper( $cache ) );
        #    print( Dumper( $parser->structure() ) );
      SKIP:
        {
            skip( "Parsing select statement fails", 2 );
        }
    }
    else
    {
        $stmt->execute($cache);
        my $rc = $stmt->execute($cache);
        ok( $rc == 1, 'SELECTED 1 row' );
        my $count = 0;
        while ( my $row = $stmt->fetch() )
        {

            #print( Dumper( $row ) );
            last if ($count);
            ++$count;
            ok( ( scalar( @{$row} ) == 1 ) && defined( $row->[0] ) && ( 'foo' eq $row->[0] ), q{got 'foo'} );
        }
    }

    $stmt = SQL::Statement->new( q{SELECT CWS FROM "TBL WITH SPACES" WHERE id=1}, $parser );
    ok( !defined( $parser->structure()->{errstr} ),
        q{Parsing SELECT CWS ...: } . ( $parser->structure()->{errstr} || '' ) );
    if ( defined( $parser->structure()->{errstr} ) )
    {

        #    print( Dumper( $cache ) );
        #    print( Dumper( $parser->structure() ) );
      SKIP:
        {
            skip( "Parsing select statement fails", 2 );
        }
    }
    else
    {
        $stmt->execute($cache);
        my $rc = $stmt->execute($cache);
        ok( $rc == 1, 'SELECTED 1 row' );
        my $count = 0;
        while ( my $row = $stmt->fetch() )
        {

            #print( Dumper( $row ) );
            last if ($count);
            ++$count;
            ok( ( scalar( @{$row} ) == 1 ) && defined( $row->[0] ) && ( 'foo' eq $row->[0] ), q{got 'foo'} );
        }
    }

    $cache = {};
    for my $sql ( split( ';', join( '', <<EOD ) ) )
CREATE TEMP TABLE T1 (id INT, CWS CHAR, "SET" INT);
INSERT INTO T1 VALUES (1, 'foo', 1);
INSERT INTO T1 VALUES (2, 'bar', 0)
EOD
    {
        $stmt = SQL::Statement->new( $sql, $parser );
        ok( $stmt->execute($cache), $sql );
    }

    $stmt = SQL::Statement->new( q{SELECT CWS FROM T1 WHERE "SET"=0}, $parser );
    ok( !defined( $parser->structure()->{errstr} ),
        q{Parsing SELECT CWS ... WHERE "SET"=0: } . ( $parser->structure()->{errstr} || '' ) );
    if ( defined( $parser->structure()->{errstr} ) )
    {

        #    print( Dumper( $cache ) );
        #    print( Dumper( $parser->structure() ) );
      SKIP:
        {
            skip( "Parsing select statement fails", 2 );
        }
    }
    else
    {
        my $rc = $stmt->execute($cache);
        ok( $rc == 1, 'SELECTED 1 row' );
        my $count = 0;
        while ( my $row = $stmt->fetch() )
        {

            #print( Dumper( $row ) );
            last if ($count);
            ++$count;
            ok( ( scalar( @{$row} ) == 1 ) && defined( $row->[0] ) && ( 'bar' eq $row->[0] ), q{got 'bar'} );
        }
    }

    $stmt = SQL::Statement->new( q{SELECT "SET" FROM T1 WHERE CWS='bar'}, $parser );
    ok( !defined( $parser->structure()->{errstr} ),
        q{Parsing SELECT "SET" ...: } . ( $parser->structure()->{errstr} || '' ) );
    if ( defined( $parser->structure()->{errstr} ) )
    {

        #    print( Dumper( $cache ) );
        #    print( Dumper( $parser->structure() ) );
      SKIP:
        {
            skip( "Parsing select statement fails", 2 );
        }
    }
    else
    {
        my $rc = $stmt->execute($cache);
        ok( $rc == 1, 'SELECTED 1 row' );
        my $count = 0;
        while ( my $row = $stmt->fetch() )
        {

            #print( Dumper( $row ) );
            last if ($count);
            ++$count;
            ok( ( scalar( @{$row} ) == 1 ) && defined( $row->[0] ) && ( 0 == $row->[0] ), q{got '0' for "SET"} );
        }
    }
