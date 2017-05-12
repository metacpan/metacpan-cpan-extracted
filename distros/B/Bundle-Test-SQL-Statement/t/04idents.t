#!/usr/bin/perl -w
use strict;
use warnings;
use lib qw(t);

use Test::More;
use TestLib qw(connect prove_reqs show_reqs test_dir);

my ( $required, $recommended ) = prove_reqs();
my ( undef, $extra_recommended ) = prove_reqs( { 'DBD::SQLite' => 0, } );
show_reqs( $required, { %$recommended, %$extra_recommended } );
my @test_dbds = ( 'SQL::Statement', grep { /^dbd:/i } keys %{$recommended} );
my $testdir = test_dir();
my @external_dbds = ( keys %$extra_recommended, grep { /^dbd::(?:dbm|csv)/i } keys %{$recommended} );

foreach my $test_dbd (@test_dbds)
{
    my ( $dbh, $sth );
    diag("Running tests for $test_dbd");
    my $temp = "";
    # XXX
    # my $test_dbd_tbl = "${test_dbd}::Table";
    # $test_dbd_tbl->can("fetch") or $temp = "$temp";
    $test_dbd eq "DBD::File"      and $temp = "TEMP";
    $test_dbd eq "SQL::Statement" and $temp = "TEMP";

    $dbh = connect(
                    $test_dbd,
                    {
                       PrintError => 0,
                       RaiseError => 0,
                       f_dir      => $testdir,
                    }
                  );

    my $external_dsn;
    if (%$extra_recommended)
    {
        if ( $extra_recommended->{'DBD::SQLite'} )
        {
            $external_dsn = "DBI:SQLite:dbname=" . File::Spec->catfile( $testdir, 'sqlite.db' );
        }
    }
    elsif (@external_dbds)
    {
        if ( $test_dbd eq $external_dbds[0] and @external_dbds > 1 )
        {
            $external_dsn = $external_dbds[1];
        }
        else
        {
            $external_dsn = $external_dbds[0];
        }
        $external_dsn =~ s/^dbd::(\w+)$/dbi:$1:/i;
        my @valid_dsns = DBI->data_sources( $external_dsn, { f_dir => $testdir } );
        $external_dsn = $valid_dsns[0];
    }

    #######################
    # identifier names
    #######################
    $dbh->do($_) for split /\n/, <<"";
	CREATE TEMP TABLE Prof (pid INT, pname VARCHAR(30))
	INSERT INTO Prof VALUES (1,'Sue')
	INSERT INTO Prof VALUES (2,'Bob')
	INSERT INTO Prof VALUES (3,'Tom')

    $sth = $dbh->prepare("SELECT * FROM Prof");
    $sth->execute();
    is_deeply( $sth->col_names(), [qw(pid pname)], "Column Names: select list = *" );

    $sth = $dbh->prepare("SELECT pname,pID FROM Prof");
    $sth->execute();
    is_deeply( $sth->col_names(), [qw(pname pID)], 'Column Names: select list = named' );

    $sth = $dbh->prepare('SELECT pname AS "ProfName", pId AS "Magic#" from prof');
    $sth->execute();
    no warnings;
    is_deeply( $sth->col_names(), [qw("ProfName" "Magic#")],
               "Column Names: select list = aliased" );
    use warnings;

    $sth = $dbh->prepare(q{SELECT pid, concat(pname, ' is #', pId ) from prof});
    $sth->execute();
    is_deeply( $sth->col_names(), [qw(pid concat)], "Column Names: select list with function" );

    $sth = $dbh->prepare(
                   q{SELECT pid AS "ID", concat(pname, ' is #', pId ) AS "explanation"  from prof});
    $sth->execute();
    is_deeply( $sth->col_names(), [qw("ID" "explanation")],
               "Column Names: select list with function = aliased" );

    my @rt34121_checks = (
        {
           descr => 'camelcased',
           cols  => [qw("fOo")],
           tbls  => [qw("SomeTable")]
        },
        {
           descr => 'reserved names',
           cols  => [qw("text")],
           tbls  => [qw("Table")]
        },
##
## According to jZed,
##
##     Verbatim from Martin Gruber and Joe Celko (who is on the standards committee
##     and whom I have talked to in person about this), _SQL Instant Reference_, Sybex
##
##         "A regular and a delimited identifier are equal if they contain the same
##         characters, taking case into account, but first converting the regular
##         (but not the delimited) identifier to all uppercase letters.  In effect
##         a delimited identifier that contains lowercase letters can never equal a
##         regular identifier although it may equal another delimited one."
##
        {
          descr => 'not quoted',
          cols  => [qw(Foo)],
          tbls  => [qw(SomeTable)],
          icols => [qw(foo)],
          itbls => [qw(sometable)],    # none quoted identifiers are lowercased internally
        },
    );
    for my $check (@rt34121_checks)
    {
        $sth = $dbh->prepare(
                              sprintf(
                                       q{SELECT %s FROM %s},
                                       join( ", ", @{ $check->{cols} } ),
                                       join( ", ", @{ $check->{tbls} } )
                                     )
                            );
        is_deeply( $sth->col_names(),
                  $check->{icols} || $check->{cols},
                  "Raw SQL hidden absent from column name [rt.cpan.org #34121] ($check->{descr})" );
        is_deeply( $sth->tbl_names(),
                   $check->{itbls} || $check->{tbls},
                   "Raw SQL hidden absent from table name [rt.cpan.org #34121] ($check->{descr})" );
    }

    $dbh->do("CREATE $temp TABLE allcols ( f1 char(10), f2 char(10) )");
    $sth = $dbh->prepare("INSERT INTO allcols (f1,f2) VALUES (?,?)")
      or diag( "Can't prepare insert sth: " . $dbh->errstr() );
    $sth->execute( 'abc', 'def' );
    my $allcols_before = $sth->all_cols();
    $sth->execute( 'abc', 'def' ) for 1 .. 100;
    my $allcols_after = $sth->all_cols();
    is_deeply( $allcols_before, $allcols_after,
               '->{all_cols} structure does not grow beyond control' );

    #########################
    # migration of t/07case.t
    #########################
    # NOTE: DBD::DBM requires at least 2 columns
    my %create = (
                   lower => "CREATE $temp TABLE tbl (id INT, col INT)",
                   upper => "CREATE $temp TABLE tbl (ID INT, COL INT)",
                   mixed => "CREATE $temp TABLE tbl (iD INT, cOl INT)",
                 );
    my %query = (
                  lower      => "SELECT id,col FROM tbl WHERE 1=0",
                  upper      => "SELECT ID,COL FROM tbl WHERE 1=0",
                  mixed      => "SELECT Id,cOl FROM tbl WHERE 1=0",
                  asterisked => "SELECT *      FROM tbl WHERE 1=0",
                );

    for my $create_case (qw(lower upper mixed))
    {
        $dbh->do("DROP TABLE IF EXISTS tbl");
        $dbh->do( $create{$create_case} );
        for my $query_case (qw(lower upper mixed asterisked))
        {
            my $sth = $dbh->prepare( $query{$query_case} );
            my $msg = sprintf( "%s/%s", $create_case, $query_case );
            ok( $sth->execute(), "execute for '$msg'" ) or diag( $dbh->errstr() );
            my $col = $sth->col_names()->[1];
            is( $col, 'col', $msg ) if ( $query_case eq 'lower' );
            is( $col, 'COL', $msg ) if ( $query_case eq 'upper' );
            is( $col, 'cOl', $msg ) if ( $query_case eq 'mixed' );
            is( $col, 'col', $msg ) if ( $query_case eq 'asterisked' );
        }
        $dbh->do("DROP TABLE IF EXISTS tbl");
    }

  SKIP:
    {
        skip( 'No external usable data source installed', 1 ) unless ($external_dsn);
        skip( "Need DBI statement handle - can't use when executing direct", 1 )
          if ( $dbh->isa('TestLib::Direct') );

        my $xb_dbh = DBI->connect($external_dsn);
        $xb_dbh->do($_) for split /\n/, <<"";
	    CREATE TABLE pg (id INT, col INT)
	    INSERT INTO pg VALUES (3,7)

        my $xb_sth = $xb_dbh->prepare("SELECT * FROM pg WHERE 1=0");
        $xb_sth->execute();
	my $nameOfCol = $xb_sth->{NAME}->[1];
        $dbh->do("CREATE $temp TABLE tbl AS IMPORT(?)",{},$xb_sth);

	for my $query_case(qw(lower upper mixed asterisked)) {
	    my $sth = $dbh->prepare( $query{$query_case} );
	    $sth->execute();
	    my $msg = sprintf( "imported table : %s", $query_case );
            my $col = $sth->col_names()->[1];
	    is($col, 'col',$msg) if $query_case eq 'lower';
	    is($col, 'COL',$msg) if $query_case eq 'upper';
	    is($col, 'cOl',$msg) if $query_case eq 'mixed';
	    is($col, $nameOfCol,$msg) if $query_case eq 'asterisked';
	}
	$xb_dbh->do("DROP TABLE pg");
	$dbh->do("DROP TABLE IF EXISTS tbl");
	$xb_dbh->disconnect;
    }
}

done_testing();
__END__
PostgreSQL
  Case insensitive comparisons
  Always stores in lower case
  Always returns lower case

S::S 0.x
  Case *sensitive* comparisons (if you created with "MYCOL" you can
     not query with "mycol" or "MyCol")
  Stores in mixed case
  Always returns stored case

SQLite and S::S 1.x
  Case insensitive comparisons
  Stores in mixed case
  Returns stored case for *, query case otherwise

Returns stored case for asterisked queries
  * except in 1.12 with TEMP files, upper-cases columns
Returns query case if columns are specified in query

S::S 1.12
  file-based table :  same as 1.x
  TEMP table       :  same, except upper cases on asterisked queries
  imported table   :  same, except upper cases on asterisked queries

