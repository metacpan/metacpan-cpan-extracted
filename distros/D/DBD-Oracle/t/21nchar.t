#!perl
#written by Lincoln A Baxter (lab@lincolnbaxter.com)

use strict;
use warnings;

use lib 't/lib';
use DBDOracleTestLib qw/ db_handle show_db_charsets set_nls_nchar test_data
                         insert_test_count select_test_count show_test_data
                         drop_table create_table insert_rows dump_table select_rows
                         force_drop_table
/;

use Test::More;
use DBI qw(:sql_types);
use DBD::Oracle qw(:ora_types ORA_OCI SQLCS_NCHAR );

my $dbh;
$| = 1;
SKIP: {
    plan skip_all =>
      'Unable to run 8bit char test, perl version is less than 5.6'
      unless ( $] >= 5.006 );

    $dbh = db_handle();

    #  $dbh->{PrintError} = 1;
    plan skip_all => 'Unable to connect to Oracle' unless $dbh;

    note("Testing control and 8 bit chars...\n");
    note("Database and client versions and character sets:\n");
    show_db_charsets($dbh);

    plan skip_all => 'Oracle charset tests unreliable for Oracle 8 client'
      if ORA_OCI() < 9.0 and !$ENV{DBD_ALL_TESTS};

    # get the database NCHARSET before we begin... if it is not UTF, then
    # use it as the client side ncharset, otherwise, use WE8ISO8859P1
    my $ncharset = $dbh->ora_nls_parameters()->{'NLS_NCHAR_CHARACTERSET'};
    $dbh->disconnect();    # we want to start over with the ncharset we select
    undef $dbh;

    if ( $ncharset =~ m/UTF/i ) {
        $ncharset = 'WE8ISO8859P1';    #WE8MSWIN1252
    }
    set_nls_nchar( $ncharset, 1 );
    $dbh = db_handle();

    my $tdata     = test_data('narrow_nchar');
    my $testcount = 0                            #create table
      + insert_test_count($tdata) + select_test_count($tdata) * 1;

    plan tests => $testcount;
    show_test_data( $tdata, 0 );

    force_drop_table($dbh);
    create_table( $dbh, $tdata );
    insert_rows( $dbh, $tdata, SQLCS_NCHAR );
    dump_table( $dbh, 'nch', 'descr' );
    select_rows( $dbh, $tdata );

    #    view_with_sqlplus(1,$tcols) if $ENV{DBD_NCHAR_SQLPLUS_VIEW};
    #    view_with_sqlplus(0,$tcols) if $ENV{DBD_NCHAR_SQLPLUS_VIEW};
}

END {
    eval {
        drop_table($dbh)
    };
}

__END__

