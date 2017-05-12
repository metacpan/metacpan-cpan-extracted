#!/usr/bin/perl -w
use strict;
use warnings;
use lib qw(t);

use Test::More;
use TestLib qw(connect prove_reqs show_reqs test_dir default_recommended);

my ( $required, $recommended ) = prove_reqs( { default_recommended(), ( MLDBM => 0 ) } );
show_reqs( $required, $recommended );
my @test_dbds = ( 'SQL::Statement', grep { /^dbd:/i } keys %{$recommended} );
my $testdir = test_dir();

foreach my $test_dbd (@test_dbds)
{
    my $dbh;
    diag("Running tests for $test_dbd");
    my $temp = "";
    # XXX
    # my $test_dbd_tbl = "${test_dbd}::Table";
    # $test_dbd_tbl->can("fetch") or $temp = "$temp";
    $test_dbd eq "DBD::File"      and $temp = "TEMP";
    $test_dbd eq "SQL::Statement" and $temp = "TEMP";

    my %extra_args;
    if ( $test_dbd eq "DBD::DBM" and $recommended->{MLDBM} )
    {
        $extra_args{dbm_mldbm} = "Storable";
    }
    $dbh = connect(
                    $test_dbd,
                    {
                       PrintError => 0,
                       RaiseError => 0,
                       f_dir      => $testdir,
                       %extra_args,
                    }
                  );

    my ( $sth, $str );

    ok( $dbh->do(qq{ CREATE $temp TABLE Tmp (id INT,phrase VARCHAR(30)) }), 'CREATE Tmp' )
      or diag( $dbh->errstr() );
    ok( $dbh->do( qq{ INSERT INTO Tmp (id,phrase) VALUES (?,?) }, {}, 9, 'yyy' ),
        'placeholder insert with named cols' )
      or diag( $dbh->errstr() );
    ok( $dbh->do( qq{ INSERT INTO Tmp VALUES(?,?) }, {}, 2, 'zzz' ),
        'placeholder insert without named cols' )
      or diag( $dbh->errstr() );
    $dbh->do( qq{ INSERT INTO Tmp (id,phrase) VALUES (?,?) }, {}, 3, 'baz' );
    ok( $dbh->do( qq{ DELETE FROM Tmp WHERE id=? or phrase=? }, {}, 3, 'baz' ),
        'placeholder delete' );
    ok( $dbh->do( qq{ UPDATE Tmp SET phrase=? WHERE id=?}, {}, 'bar', 2 ), 'placeholder update' );
    ok( $dbh->do( qq{ UPDATE Tmp SET phrase=?,id=? WHERE id=? and phrase=?},
                  {}, 'foo', 1, 9, 'yyy' ),
        'placeholder update' );
    ok( $dbh->do( qq{INSERT INTO Tmp VALUES (3, 'baz'), (4, 'fob'),
(5, 'zab')} ),
        'multiline insert' );
    $sth = $dbh->prepare('SELECT id,phrase FROM Tmp ORDER BY id');
    $sth->execute();
    $str = '';
    while ( my $r = $sth->fetch_row() ) { $str .= "@$r^"; }
    cmp_ok( $str, 'eq', '1 foo^2 bar^3 baz^4 fob^5 zab^', 'verify table contents' );
    ok( $dbh->do(qq{ DROP TABLE IF EXISTS Tmp }), 'DROP TABLE' );

    ########################################
    # CREATE, INSERT, UPDATE, DELETE, SELECT
    ########################################
    ok( $dbh->do($_), $dbh->command() ) for split /\n/, <<"";
        CREATE $temp TABLE phrase (id INT,phrase VARCHAR(30))
	INSERT INTO phrase VALUES(1,UPPER(TRIM(' foo ')))
	INSERT INTO phrase VALUES(2,'baz')
	INSERT INTO phrase VALUES(3,'qux')
	UPDATE phrase SET phrase=UPPER(TRIM(LEADING 'z' FROM 'zbar')) WHERE id=3
	DELETE FROM phrase WHERE id = 2

    $sth = $dbh->prepare("SELECT UPPER('a') AS A,phrase FROM phrase");
    $sth->execute;
    $str = '';
    while ( my $r = $sth->fetch_row() ) { $str .= "@$r^"; }
    ok( $str eq 'A FOO^A BAR^', 'SELECT' );
    cmp_ok( scalar $dbh->selectrow_array("SELECT COUNT(*) FROM phrase"), '==', 2, 'COUNT *' );

    ok( $dbh->do("DROP TABLE phrase"), "DROP $temp TABLE" );

    #################################
    # COMPUTED COLUMNS IN SELECT LIST
    #################################
    cmp_ok( $dbh->selectrow_array("SELECT UPPER('b')"),
            'eq', 'B', 'COMPUTED COLUMNS IN SELECT LIST' );

    ###########################
    # CREATE function in script
    ###########################
    $dbh->do("CREATE FUNCTION froog");
    sub froog { 99 }
    ok( '99' eq $dbh->selectrow_array("SELECT froog"), 'CREATE FUNCTION from script' );


    for my $sql (
	split /\n/, <<""
	CREATE $temp TABLE a (b INT, c CHAR)
	INSERT INTO a VALUES(1,'abc')
	INSERT INTO a VALUES(2,'efg')
	INSERT INTO a VALUES(3,'hij')
	INSERT INTO a VALUES(4,'klm')
	INSERT INTO a VALUES(5,'nmo')
	INSERT INTO a VALUES(6,'pqr')
	INSERT INTO a VALUES(7,'stu')
	INSERT INTO a VALUES(8,'vwx')
	INSERT INTO a VALUES(9,'yz')
	SELECT b,c FROM a WHERE c LIKE '%b%' ORDER BY c DESC"

		)
    {
	note("<$sql>");
	$sth = $dbh->prepare( $sql );
	ok( $sth->execute(), '$stmt->execute "' . $sql . '" (' . $sth->command() . ')' );
	next unless ( $sth->command() eq 'SELECT' );
	cmp_ok( ref( $sth->where_hash ),  'eq', 'HASH', '$stmt->where_hash' );
	cmp_ok( $sth->columns(0)->name(), 'eq', 'b',    '$stmt->columns' );
	cmp_ok( join( '', @{$sth->col_names()} ), 'eq', 'bc', '$stmt->column_names' );
	cmp_ok( $sth->order(0)->{direction}, 'eq', 'DESC', '$stmt->order' );

	while ( my $row = $sth->fetch_row() )
	{
	    cmp_ok( $row->[0], '==', 1, '$stmt->fetch' );
	}
    }

    my %gen_inbtw = (
	q{SELECT b,c FROM a WHERE b IN (2,3,5,7)}      => '2^efg^3^hij^5^nmo^7^stu',
	q{SELECT b,c FROM a WHERE b NOT IN (2,3,5,7)}  => '1^abc^4^klm^6^pqr^8^vwx^9^yz',
	q{SELECT b,c FROM a WHERE NOT b IN (2,3,5,7)}  => '1^abc^4^klm^6^pqr^8^vwx^9^yz',
	q{SELECT b,c FROM a WHERE b BETWEEN (5,7)}     => '5^nmo^6^pqr^7^stu',
	q{SELECT b,c FROM a WHERE b NOT BETWEEN (5,7)} => '1^abc^2^efg^3^hij^4^klm^8^vwx^9^yz',
	q{SELECT b,c FROM a WHERE NOT b BETWEEN (5,7)} => '1^abc^2^efg^3^hij^4^klm^8^vwx^9^yz',
	q{SELECT b,c FROM a WHERE c IN ('abc','klm','pqr','vwx','yz')}     => '1^abc^4^klm^6^pqr^8^vwx^9^yz',
	q{SELECT b,c FROM a WHERE c NOT IN ('abc','klm','pqr','vwx','yz')} => '2^efg^3^hij^5^nmo^7^stu',
	q{SELECT b,c FROM a WHERE NOT c IN ('abc','klm','pqr','vwx','yz')} => '2^efg^3^hij^5^nmo^7^stu',
	q{SELECT b,c FROM a WHERE c BETWEEN ('abc','nmo')}     => '1^abc^2^efg^3^hij^4^klm^5^nmo',
	q{SELECT b,c FROM a WHERE c NOT BETWEEN ('abc','nmo')} => '6^pqr^7^stu^8^vwx^9^yz',
	q{SELECT b,c FROM a WHERE NOT c BETWEEN ('abc','nmo')} => '6^pqr^7^stu^8^vwx^9^yz',
    );

    while ( my ( $sql, $result ) = each(%gen_inbtw) )
    {
	my $sth = $dbh->prepare($sql);
	ok( $sth->execute(), '$stmt->execute "' . $sql . '" (' . $sth->command . ')' );
	my @res;
	while ( my $row = $sth->fetch_row() )
	{
	    push( @res, @{$row} );
	}
	is( $result, join( '^', @res ), $sql );
    }


    ###########################
    # CREATE function in module
    ###########################
    BEGIN
    {
        eval 'package Foo; sub foo { 88 } sub bar { return $_[2] * 2; } 1;';
    }
    $dbh->do(qq{CREATE FUNCTION foofoo NAME "Foo::foo"});
    $dbh->do(qq{CREATE FUNCTION foobar NAME "Foo::bar"});
    ok( 88 == $dbh->selectrow_array("SELECT foofoo"), 'CREATE FUNCTION from module' );
    ok( 42 == $dbh->selectrow_array("SELECT foobar(21)"), 'CREATE FUNCTION from module with argument' );

    ################
    # LOAD functions
    ################
    SKIP: {
	-e 'Bar.pm' and unlink 'Bar.pm';
	my $fh;
	open( $fh, '>Bar.pm' ) or skip(1, $!);
	print $fh "package Bar; sub SQL_FUNCTION_BAR{77};1;";
	close $fh;
	$dbh->do("LOAD Bar");
	ok( 77 == $dbh->selectrow_array("SELECT bar"), 'LOAD FUNCTIONS' );
    }
    -e 'Bar.pm' and unlink 'Bar.pm';

    #my $foo=0;
    #sub test2 {$foo = 6;}
    #open(O,'>','tmpss.sql') or die $!;
    #print O "SELECT test2";
    #close O;
    #$dbh->do("CREATE FUNCTION test2");
    #ok($dbh->do(qq{CALL RUN('tmpss.sql')}),'run');
    #ok(6==$foo,'call run');
    #unlink 'tmpss.sql' if -e 'tmpss.sql';

  SKIP:
    {
        if ( $test_dbd eq "DBD::DBM" and !$recommended->{MLDBM} )
        {
            skip( "DBD::DBM Update test won't run without MLDBM", 3 );
        }
        my $pauli = [
                      [ 1, 'H',   19 ],
                      [ 2, 'H',   21 ],
                      [ 3, 'KK',  1 ],
                      [ 4, 'KK',  2 ],
                      [ 5, 'KK',  13 ],
                      [ 6, 'MMM', 25 ],
                    ];
        ok( $dbh->do(qq{CREATE $temp TABLE pauli (id INT, column1 VARCHAR, column2 INTEGER)}),
            'CREATE pauli test table' )
          or diag( $dbh->errstr() );
        $sth = $dbh->prepare("INSERT INTO pauli VALUES (?, ?, ?)");
        foreach my $line ( @{$pauli} )
        {
            $sth->execute( @{$line} );
        }
        $sth = $dbh->prepare("UPDATE pauli SET column1 = ? WHERE column1 = ?");
        my $cnt = $sth->execute( "XXXX", "KK" );
        cmp_ok( $cnt, '==', 3, 'UPDATE with placeholders' );
        $sth->finish();

        $sth = $dbh->prepare("SELECT column1, COUNT(column1) FROM pauli GROUP BY column1");
        $sth->execute();
        my $hres = $sth->fetchall_hashref('column1');
        cmp_ok( $hres->{XXXX}->{'COUNT'}, '==', 3, 'UPDATE with placeholder updates correct' );
    }
}

done_testing();
