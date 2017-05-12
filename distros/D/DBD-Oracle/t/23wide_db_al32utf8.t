#!perl -w
#written by Lincoln A Baxter (lab@lincolnbaxter.com)

use strict;
#use warnings;
use Test::More;

use DBI qw(:sql_types);
use DBD::Oracle qw( :ora_types ORA_OCI SQLCS_NCHAR );

unshift @INC ,'t';
require 'nchar_test_lib.pl';

my $dbh;
$| = 1;
SKIP: {

    plan skip_all => "Unable to run unicode test, perl version is less than 5.6"
	unless ( $] >= 5.006 );
    plan skip_all => "Oracle charset tests unreliable for Oracle 8 client"
	if ORA_OCI() < 9.0 and !$ENV{DBD_ALL_TESTS};

    set_nls_lang_charset( (ORA_OCI >= 9.2) ? 'AL32UTF8' : 'UTF8', 1 );
    $dbh = db_handle();

    plan skip_all => "Unable to connect to Oracle" if not $dbh;
    plan skip_all => "Database character set is not Unicode" if not db_ochar_is_utf($dbh) ;
    # testing utf8 with char columns (wide mode database)

    my $tdata = test_data( 'wide_char' );
    my $testcount = 0 #create table
                  + insert_test_count( $tdata )
                  + select_test_count( $tdata ) * 1;
                  ;

    plan tests => $testcount;
    show_test_data( $tdata ,0 );
    drop_table($dbh);
    create_table( $dbh, $tdata );
    insert_rows( $dbh, $tdata ,SQLCS_NCHAR);
    dump_table( $dbh ,'ch' ,'descr' );
    select_rows( $dbh, $tdata );
}

END {
    eval {
        local $dbh->{PrintError} = 0;
	     drop_table($dbh) if $dbh and not $ENV{'DBD_SKIP_TABLE_DROP'};
    };
}

