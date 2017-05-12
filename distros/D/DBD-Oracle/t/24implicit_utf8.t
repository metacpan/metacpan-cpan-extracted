#!perl -w
#written by Lincoln A Baxter (lab@lincolnbaxter.com)

use strict;
#use warnings;
use Test::More;

unshift @INC ,'t';
require 'nchar_test_lib.pl';

use DBI qw(:sql_types);
use DBD::Oracle qw(:ora_types ORA_OCI SQLCS_NCHAR );

my $dbh;
$| = 1;
SKIP: {
    plan skip_all => "Unable to run 8bit char test, perl version is less than 5.6" unless ( $] >= 5.006 );
    plan skip_all => "Oracle charset tests unreliable for Oracle 8 client"
        if ORA_OCI() < 9.0 and !$ENV{DBD_ALL_TESTS};
    $dbh = db_handle();	# just to check connection and db NCHAR character set

    plan skip_all => "Unable to connect to Oracle" if not $dbh;
    plan skip_all => "Database NCHAR character set is not Unicode" if not db_nchar_is_utf($dbh) ;
    plan skip_all => "database character set is not Unicode" unless db_ochar_is_utf($dbh);
    $dbh->disconnect();

    # testing implicit csform (dbhimp.c sets csform implicitly)
    my $tdata = test_data( 'wide_nchar' );
    my $testcount = 0
                  + insert_test_count( $tdata )
                  + select_test_count( $tdata ) * 1;
                  ;

    my @nchar_cset = (ORA_OCI >= 9.2) ? qw(UTF8 AL32UTF8) : qw(UTF8);
    plan tests => $testcount * @nchar_cset;
    show_test_data( $tdata ,0 );

    foreach my $nchar_cset (@nchar_cset)  {
        $dbh->disconnect() if $dbh;
	undef $dbh;
        # testing with NLS_NCHAR=$nchar_cset
        SKIP: {
            set_nls_nchar( $nchar_cset ,1 );
            $dbh = db_handle();
	    show_db_charsets($dbh);
            skip "failed to connect to oracle with NLS_NCHAR=$nchar_cset" ,$testcount if not $dbh;
            drop_table($dbh);
            create_table( $dbh, $tdata );
            insert_rows( $dbh, $tdata );
            dump_table( $dbh ,'nch' ,'descr' );
            select_rows( $dbh, $tdata );
        }
    }
}

END {
    eval {
        local $dbh->{PrintError} = 0;
	     drop_table( $dbh ) if $dbh and not $ENV{'DBD_SKIP_TABLE_DROP'};
    };
}

__END__

