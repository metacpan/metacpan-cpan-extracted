#!/usr/bin/perl -w
use strict;
use warnings;
use lib qw(t);

use Test::More;
use Params::Util qw(_INSTANCE);
use TestLib qw(connect prove_reqs show_reqs);

my ( $required, $recommended ) = prove_reqs();
my @test_dbds = ( 'SQL::Statement', grep { /^dbd:/i } keys %{$recommended} );

foreach my $test_dbd (@test_dbds)
{
    my $dbh;

    # Test RaiseError for prepare errors
    #
    my %extra_args;
    if ( $test_dbd =~ m/^DBD::/i )
    {
	$extra_args{sql_dialect} = "ANSI";
    }
    $dbh = connect(
                    $test_dbd,
                    {
                       PrintError => 0,
                       RaiseError => 0,
		       %extra_args,
                    }
                  );

    for my $sql(
		split /\n/, <<""
  /* DROP TABLE */
DROP TABLE foo
DROP TABLE foo CASCADE
DROP TABLE foo RESTRICT
  /* DELETE */
DELETE FROM foo
DELETE FROM foo WHERE id < 7
  /* UPDATE */
UPDATE foo SET bar = 7
UPDATE foo SET bar = 7 WHERE id > 7
  /* INSERT */
INSERT INTO foo VALUES ( 'baz', 7, NULL )
INSERT INTO foo (col1,col2,col7) VALUES ( 'baz', 7, NULL )
  /* CREATE TABLE */
CREATE TABLE foo ( id INT )
CREATE LOCAL TEMPORARY TABLE foo (id INT)
CREATE LOCAL TEMPORARY TABLE foo (id INT) ON COMMIT DELETE ROWS
CREATE LOCAL TEMPORARY TABLE foo (id INT) ON COMMIT PRESERVE ROWS
CREATE GLOBAL TEMPORARY TABLE foo (id INT)
CREATE GLOBAL TEMPORARY TABLE foo (id INT) ON COMMIT DELETE ROWS
CREATE GLOBAL TEMPORARY TABLE foo (id INT) ON COMMIT PRESERVE ROWS
CREATE TABLE foo ( id INTEGER, phrase VARCHAR(40) )
CREATE TABLE foo ( id INTEGER UNIQUE, phrase VARCHAR(40) UNIQUE )
CREATE TABLE foo ( id INTEGER PRIMARY KEY, phrase VARCHAR(40) UNIQUE )
CREATE TABLE foo ( id INTEGER PRIMARY KEY, phrase VARCHAR(40) NOT NULL )
CREATE TABLE foo ( id INTEGER NOT NULL, phrase VARCHAR(40) NOT NULL )
CREATE TABLE foo ( id INTEGER UNIQUE NOT NULL, phrase VARCHAR(40) )
CREATE TABLE foo ( phrase CHARACTER VARYING(255) )
CREATE TABLE foo ( phrase NUMERIC(4,6) )
CREATE TABLE foo ( id INTEGER, phrase VARCHAR(40), CONSTRAINT "foo_pkey" PRIMARY KEY ( "id", "phrase" ), CONSTRAINT "foo_fkey" FOREIGN KEY ( "id" ) REFERENCES "bar" ( "bar_id" ))
CREATE TABLE foo ( id INTEGER, phrase VARCHAR(40), PRIMARY KEY ( "id" ), FOREIGN KEY ("id", "phrase") REFERENCES "bar" ("id2", "phrase2"))
CREATE TABLE foo ( id INTEGER, phrase CHAR(255), phrase2 VARCHAR(40), CONSTRAINT "foo_pkey" PRIMARY KEY ( "id", phrase, "phrase2" ), CONSTRAINT "foo_fkey" FOREIGN KEY ("id", "phrase", "phrase2") REFERENCES "bar" ("id2", "phrase2", "phase10"))
  /* JOINS */
SELECT Lnum,Llet,Ulet FROM zLower NATURAL INNER JOIN zUpper
SELECT Lnum,Llet,Ulet FROM zLower NATURAL LEFT JOIN zUpper
SELECT Lnum,Llet,Ulet FROM zLower NATURAL RIGHT JOIN zUpper
SELECT Lnum,Llet,Ulet FROM zLower NATURAL FULL JOIN zUpper
SELECT Lnum,Llet,Ulet FROM zLower INNER JOIN zUpper ON Lnum = Unum
SELECT Lnum,Llet,Ulet FROM zLower LEFT JOIN zUpper ON Lnum = Unum
SELECT Lnum,Llet,Ulet FROM zLower RIGHT JOIN zUpper ON Lnum = Unum
SELECT Lnum,Llet,Ulet FROM zLower FULL JOIN zUpper ON Lnum = Unum
SELECT Lnum,Llet,Ulet FROM zLower INNER JOIN zUpper USING(num)
SELECT Lnum,Llet,Ulet FROM zLower LEFT JOIN zUpper USING(num)
SELECT Lnum,Llet,Ulet FROM zLower RIGHT JOIN zUpper USING(num)
SELECT Lnum,Llet,Ulet FROM zLower FULL JOIN zUpper USING(num)
SELECT Lnum,Llet,Ulet FROM zLower,zUpper WHERE Lnum = Unum
SELECT * FROM zLower NATURAL INNER JOIN zUpper
SELECT * FROM zLower NATURAL LEFT JOIN zUpper
SELECT * FROM zLower NATURAL RIGHT JOIN zUpper
SELECT * FROM zLower NATURAL FULL JOIN zUpper
SELECT * FROM zLower INNER JOIN zUpper ON Lnum = Unum
SELECT * FROM zLower LEFT JOIN zUpper ON Lnum = Unum
SELECT * FROM zLower RIGHT JOIN zUpper ON Lnum = Unum
SELECT * FROM zLower FULL JOIN zUpper ON Lnum = Unum
SELECT * FROM zLower INNER JOIN zUpper USING(num)
SELECT * FROM zLower LEFT JOIN zUpper USING(num)
SELECT * FROM zLower RIGHT JOIN zUpper USING(num)
SELECT * FROM zLower FULL JOIN zUpper USING(num)
SELECT * FROM zLower,zUpper WHERE Lnum = Unum
  /* SELECT COLUMNS */
SELECT id, phrase FROM foo
SELECT * FROM foo
SELECT DISTINCT * FROM foo
SELECT ALL * FROM foo
SELECT A.*,B.* FROM A,B WHERE A.id=B.id
  /* SET FUNCTIONS */
SELECT MAX(foo) FROM bar
SELECT MIN(foo) FROM bar
SELECT AVG(foo) FROM bar
SELECT SUM(foo) FROM bar
SELECT COUNT(foo) FROM foo
SELECT COUNT(*) FROM foo
SELECT SUM(DISTINCT foo) FROM bar
SELECT SUM(ALL foo) FROM bar
  /* ORDER BY */
SELECT * FROM foo ORDER BY bar
SELECT * FROM foo ORDER BY bar, baz
SELECT * FROM foo ORDER BY bar DESC
SELECT * FROM foo ORDER BY bar ASC
  /* LIMIT */
SELECT * FROM foo LIMIT 5
SELECT * FROM foo LIMIT 0, 5
SELECT * FROM foo LIMIT 5, 10
  /* STRING FUNCTIONS */
SELECT * FROM foo WHERE UPPER(phrase) = 'bar'
SELECT * FROM foo WHERE LOWER(phrase) = 'bar'
SELECT * FROM foo WHERE TRIM( str ) = 'bar'S
SELECT * FROM foo WHERE TRIM( LEADING FROM str ) = 'bar'
SELECT * FROM foo WHERE TRIM( TRAILING FROM str ) = 'bar'
SELECT * FROM foo WHERE TRIM( BOTH FROM str ) = 'bar'
SELECT * FROM foo WHERE TRIM( LEADING ';' FROM str ) = 'bar'
SELECT * FROM foo WHERE TRIM( UPPER(phrase) ) = 'bar'
SELECT * FROM foo WHERE TRIM( LOWER(phrase) ) = 'bar'
SELECT * FROM foo WHERE blat= SUBSTRING(bar FROM 3 FOR 6)
SELECT * FROM foo WHERE blat= SUBSTRING(bar FROM 3)
UPDATE foo SET bar='baz', bop=7, bump=bar+8, blat=SUBSTRING(bar FROM 3 FOR 6)
  /* TABLE NAME ALIASES */
SELECT * FROM test as T1
SELECT * FROM test T1
SELECT T1.id, T2.num FROM test as T1 JOIN test2 as T2 USING(id)
SELECT id FROM test as T1 WHERE T1.num < 7
SELECT id FROM test as T1 ORDER BY T1.num
SELECT a.x,b.y FROM foo AS a, bar b WHERE a.baz = b.bop ORDER BY a.blat
  /* NUMERIC EXPRESSIONS */
SELECT * FROM foo WHERE 1 = 0 AND baz < (6*foo+11-r)
  /* CASE OF IDENTIFIERS */
SELECT ID, phRase FROM tEst AS tE WHERE te.id < 3 ORDER BY TE.phrasE
  /* PARENS */
SELECT * FROM ztable WHERE NOT data IN ('one','two')
SELECT * from ztable WHERE (aaa > 'AAA')
SELECT * from ztable WHERE  sev = 50 OR sev = 60
SELECT * from ztable WHERE (sev = 50 OR sev = 60)
SELECT * from ztable WHERE sev IN (50,60)
SELECT * from ztable WHERE rc > 200 AND ( sev IN(50,60) )
SELECT * FROM ztable WHERE data NOT IN ('one','two')
SELECT * from ztable WHERE (aaa > 'AAA') AND (zzz < 'ZZZ')
SELECT * from ztable WHERE (sev IN(50,60))
  /* NOT */
SELECT * FROM foo WHERE NOT bar = 'baz' AND bop = 7 OR NOT blat = bar
SELECT * FROM foo WHERE NOT bar = 'baz' AND NOT bop = 7 OR NOT blat = bar
SELECT * FROM foo WHERE NOT bar = 'baz' AND NOT bop = 7 OR blat IS NOT NULL
  /* IN */
SELECT * FROM bar WHERE foo IN ('aa','ab','ba','bb')
SELECT * FROM bar WHERE foo IN (3.14,2.72,1.41,9.81)
SELECT * FROM bar WHERE foo NOT IN ('aa','ab','ba','bb')
SELECT * FROM bar WHERE foo NOT IN (3.14,2.72,1.41,9.81)
  /* BETWEEN */
SELECT * FROM bar WHERE foo BETWEEN ('aa','bb')
SELECT * FROM bar WHERE foo BETWEEN (1.41,9.81)
SELECT * FROM bar WHERE foo NOT BETWEEN ('aa','bb')
SELECT * FROM bar WHERE foo NOT BETWEEN (1.41,9.81)

	       ) {
	ok( eval { $dbh->prepare($sql); }, "parse '$sql' using $test_dbd" ) or diag( $dbh->errstr() );
    }

    SKIP:
    {
	my $sql = "SELECT a FROM b JOIN c WHERE c=? AND e=7 ORDER BY f ASC, g DESC LIMIT 5,2";
	my $sth;
	eval { $sth = $dbh->prepare( $sql ) };
	ok( !$@, '$sth->new' ) or skip("Can't instantiate SQL::Statement: $@");
	cmp_ok( $sth->command,           'eq', 'SELECT', '$sth->command' );
	cmp_ok( scalar( $sth->params ),  '==', 1,        '$sth->params' );
	cmp_ok( $sth->tables(1)->name(), 'eq', 'c',      '$sth->tables' );
	ok( defined( _INSTANCE( $sth->where(), 'SQL::Statement::Operation::And' ) ),
	    '$sth->where()->op' );
	ok( defined( _INSTANCE( $sth->where()->{LEFT}, 'SQL::Statement::Operation::Equal' ) ),
	    '$sth->where()->left' );
	ok( defined( _INSTANCE( $sth->where()->{LEFT}->{LEFT}, 'SQL::Statement::ColumnValue' ) ),
	    '$sth->where()->left->left' );
	ok( defined( _INSTANCE( $sth->where()->{LEFT}->{RIGHT}, 'SQL::Statement::Placeholder' ) ),
	    '$sth->where()->left->right' );
	cmp_ok( $sth->limit(),  '==', 2, '$sth->limit' );
	cmp_ok( $sth->offset(), '==', 5, '$sth->offset' );

	note( "Command      " . $sth->command() );
	note( "Num Pholders " . scalar $sth->params() );
	note( "Columns      " . join ',', map { $_->name } $sth->columns() );
	note( "Tables       " . join ',', $sth->tables() );
	note( "Where op     " . join ',', $sth->where->op() );
	note( "Limit        " . $sth->limit() );
	note( "Offset       " . $sth->offset );
	my @order_cols = $sth->order();
	note( "Order Cols   " . join( ',', map { keys %$_ } @order_cols ) );
    }

    my $sth = $dbh->prepare( "INSERT a VALUES(3,7)" );
    cmp_ok( scalar( $sth->row_values() ),  '==', 1, '$stmt->row_values()' );
    cmp_ok( scalar( $sth->row_values(0) ), '==', 2, '$stmt->row_values(0)' );
    cmp_ok( scalar( $sth->row_values( 0, 1 ) )->{value}, '==', 7, '$stmt->row_values(0,1)' );
    cmp_ok( ref( $sth->parser()->structure ), 'eq', 'HASH',   'structure' );
    cmp_ok( $sth->parser()->command(),        'eq', 'INSERT', 'command' );

    ok( $dbh->prepare( "SELECT DISTINCT c1 FROM tbl" ), 'distinct' );
}
done_testing();
