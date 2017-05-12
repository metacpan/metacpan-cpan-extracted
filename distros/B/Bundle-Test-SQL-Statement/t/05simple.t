#!/usr/bin/perl -w
use strict;
use warnings;
use lib qw(t);

use Test::More;
use TestLib qw(connect prove_reqs show_reqs test_dir default_recommended);

use Params::Util qw(_CODE _ARRAY);

my ( $required, $recommended ) = prove_reqs( { default_recommended(), ( MLDBM => 0 ) } );
show_reqs( $required, $recommended );
my @test_dbds = ( 'SQL::Statement', grep { /^dbd:/i } keys %{$recommended} );
my $testdir = test_dir();

my @massValues = map { [ $_, ( "a" .. "f" )[ int rand 6 ], int rand 10 ] } ( 1 .. 3999 );

SKIP:
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
    if ( $test_dbd eq "DBD::DBM" )
    {
        if ( $recommended->{MLDBM} )
        {
            $extra_args{dbm_mldbm} = "Storable";
        }
        else
        {
            skip( 'DBD::DBM test runs without MLDBM', 1 );
        }
    }
    elsif( $test_dbd eq "DBD::CSV" )
    {
	$extra_args{csv_null} = 1;
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

    # basic tests taken from DBD::DBM simple tests - should work overall
    my @tests = (
    	"DROP TABLE IF EXISTS multi_fruit", -1,
	"CREATE $temp TABLE multi_fruit (dKey INT, dVal VARCHAR(10), qux INT)", '0E0',
	"INSERT INTO  multi_fruit VALUES (1,'oranges'  , 11 )", 1,
	"INSERT INTO  multi_fruit VALUES (2,'to_change',  0 )", 1,
	"INSERT INTO  multi_fruit VALUES (3, NULL      , 13 )", 1,
	"INSERT INTO  multi_fruit VALUES (4,'to_delete', 14 )", 1,
	"INSERT INTO  multi_fruit VALUES (?,?,?); #5,via placeholders,15", 1,
	"INSERT INTO  multi_fruit VALUES (6,'to_delete', 16 )", 1,
	"INSERT INTO  multi_fruit VALUES (7,'to delete', 17 )", 1,
	"INSERT INTO  multi_fruit VALUES (8,'to remove', 18 )", 1,
	"UPDATE multi_fruit SET dVal='apples', qux='12' WHERE dKey=2", 1,
	"DELETE FROM  multi_fruit WHERE dVal='to_delete'", 2,
	"DELETE FROM  multi_fruit WHERE qux=17", 1,
	"DELETE FROM  multi_fruit WHERE dKey=8", 1,
	"SELECT * FROM multi_fruit ORDER BY dKey DESC", [
	    [ 5, 'via placeholders', 15 ],
	    [ 3, undef, 13 ],
	    [ 2, 'apples', 12 ],
	    [ 1, 'oranges', 11 ],
	],
	"DELETE FROM multi_fruit", 4,
	"SELECT COUNT(*) FROM multi_fruit", [ [ 0 ] ],
	"DROP TABLE multi_fruit", -1,
    );

    SKIP:
    for my $idx ( 0 .. $#tests ) {
	$idx % 2 and next;
	my $sql = $tests[$idx];
	my $result = $tests[$idx+1];
        $sql =~ s/;$//;

        $sql =~ s/\s*;\s*(?:#(.*))//;
        my $comment = $1;

        my $sth = $dbh->prepare($sql);
        ok($sth, "prepare $sql using $test_dbd") or diag($dbh->errstr || 'unknown error');

	my @bind;
#	if($sth->{NUM_OF_PARAMS})
#	{
#	    @bind = split /,/, $comment;
#	}
	$comment and @bind = split /,/, $comment;
        # if execute errors we will handle it, not PrintError:
        my $n = $sth->execute(@bind);
        ok($n, "execute $sql using $test_dbd") or diag($sth->errstr || 'unknown error');
        next if (!defined($n));

	is( $n, $result, $sql ) unless( 'ARRAY' eq ref $result );
	TODO: {
	    local $TODO = "AUTOPROXY drivers might throw away sth->rows()" if($ENV{DBI_AUTOPROXY});
	    is( $n, $sth->rows(), "\$sth->execute($sql) == \$sth->rows using $test_dbd") if( $sql =~ m/^(?:UPDATE|DELETE)/ );
	}
        next unless $sql =~ /SELECT/;
	my $allrows = $sth->fetch_rows();
	my $expected_rows = $result;
	is( $sth->rows, scalar( @{$expected_rows} ), $sql );
	is_deeply( $allrows, $expected_rows, "SELECT results for $sql using $test_dbd" );
    }
}

done_testing();
