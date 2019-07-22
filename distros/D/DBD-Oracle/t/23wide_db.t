#!perl
#written by Lincoln A Baxter (lab@lincolnbaxter.com)

use strict;
use warnings;

use lib 't/lib';
use DBDOracleTestLib qw/
    set_nls_lang_charset db_handle db_ochar_is_utf test_data
    insert_test_count select_test_count show_test_data
    force_drop_table create_table insert_rows dump_table
    select_rows
    /;

use Test::More;

use DBI qw(:sql_types);
use DBD::Oracle qw( :ora_types ORA_OCI SQLCS_NCHAR );

my $dbh;
$| = 1;
SKIP: {

    plan skip_all => 'Unable to run unicode test, perl version is less than 5.6'
      unless ( $] >= 5.006 );
    plan skip_all => 'Oracle charset tests unreliable for Oracle 8 client'
      if ORA_OCI() < 9.0 and !$ENV{DBD_ALL_TESTS};

   #!  #force Ncharset to NON UTF8! we are testing a wide database where someone
   #!  #perversely sets nchar to non utf8, and nls_lang to utf8....
    set_nls_lang_charset( ( ORA_OCI >= 9.2 ) ? 'AL32UTF8' : 'UTF8', 1 );

#!  #set_nls_nchar( 'WE8ISO8859P1' ,1 ); #it breaks and it is stupid to do this... doc it XXX
    $dbh = db_handle();

    plan skip_all => 'Unable to connect to Oracle' unless $dbh;
    plan skip_all => 'Database character set is not Unicode'
      unless db_ochar_is_utf($dbh);

    # testing utf8 with char columns (wide mode database)

    my $tdata     = test_data('wide_char');
    my $testcount = 0                         #create table
      + insert_test_count($tdata) + select_test_count($tdata) * 1;

    plan tests => $testcount;
    show_test_data( $tdata, 0 );
    force_drop_table($dbh);
    create_table( $dbh, $tdata );
    insert_rows( $dbh, $tdata, SQLCS_NCHAR );
    dump_table( $dbh, 'ch', 'descr' );
    select_rows( $dbh, $tdata );

}    # SKIP

END {
    eval { drop_table($dbh); };
}

