#!perl
#written by Lincoln A Baxter (lab@lincolnbaxter.com)

use strict;
use warnings;
use Test::More;

use DBI qw(:sql_types);
use DBD::Oracle qw( :ora_types ORA_OCI SQLCS_NCHAR );

use lib 't/lib';
use DBDOracleTestLib qw/
    db_handle drop_table force_drop_table
    test_data show_test_data select_rows
    create_table insert_rows dump_table
    set_nls_lang_charset db_ochar_is_utf
    insert_test_count select_test_count
/;

my $dbh;
$| = 1;
SKIP: {

    plan skip_all => 'Unable to run unicode test, perl version is less than 5.6'
        unless ( $] >= 5.006 );
    plan skip_all => 'Oracle charset tests unreliable for Oracle 8 client'
        if ORA_OCI() < 9.0 and !$ENV{DBD_ALL_TESTS};

    set_nls_lang_charset( (ORA_OCI >= 9.2) ? 'AL32UTF8' : 'UTF8', 1 );
    $dbh = db_handle();

    plan skip_all => 'Unable to connect to Oracle' unless $dbh;
    plan skip_all => 'Database character set is not Unicode' unless db_ochar_is_utf($dbh) ;
    # testing utf8 with char columns (wide mode database)

    my $tdata = test_data( 'wide_char' );
    my $testcount = 0 #create table
                  + insert_test_count( $tdata )
                  + select_test_count( $tdata ) * 1;
                  ;

    plan tests => $testcount;
    show_test_data( $tdata ,0 );
    force_drop_table($dbh);
    create_table( $dbh, $tdata );
    insert_rows( $dbh, $tdata ,SQLCS_NCHAR);
    dump_table( $dbh ,'ch' ,'descr' );
    select_rows( $dbh, $tdata );

} # SKIP

END {
    drop_table($dbh)
}

