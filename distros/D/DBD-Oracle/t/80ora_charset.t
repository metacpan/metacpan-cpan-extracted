#!perl -w
use strict;

use Encode;
use Devel::Peek;

use DBI;
use DBD::Oracle qw(ORA_OCI);

use Test::More;

unshift @INC ,'t';
require 'nchar_test_lib.pl';

my $tdata = {
    cols => [
        [ 'ch', 'varchar2(20)', ],
        [ 'nch', 'nvarchar2(20)', ],
        [ 'descr', 'varchar2(50)', ],
    ],
    'dump' => 'DUMP(%s)',
    rows => [
        [
            "\xb0",
            "\xb0",
            'DEGREE SIGN',
        ],
    ],
};

my $table = table();

my $utf8_charset = (ORA_OCI >= 9.2) ? 'AL32UTF8' : 'UTF8';
my $eight_bit_charset = 'WE8ISO8859P1';

my $dbh_utf8;
my $dbh;
SKIP: {
    plan skip_all => "Oracle 9.2 or newer required" unless ORA_OCI >= 9.2;

    if ($ENV{ORA_CHARSET_FAIL}) {
        # Connecting up here breaks because of the charset and ncharset
        # global variables defined in dbdimp.c
        $dbh_utf8 = db_connect(1);
    }
    my $testcount = 8 + insert_test_count( $tdata );

    $dbh = db_connect(0);
    if ($dbh) {
        $dbh->ora_nls_parameters ()->{NLS_CHARACTERSET} =~ m/US7ASCII/ and plan skip_all => "Database is set up as US7ASCII";

        plan tests => $testcount;
    } else {
        plan skip_all => "Unable to connect to Oracle";
    }

    show_test_data( $tdata ,0 );

    drop_table($dbh);
    create_table($dbh, $tdata);
    insert_rows( $dbh, $tdata);

    my ($ch, $nch) = $dbh->selectrow_array("select ch, nch from $table");
    check($ch, $nch, 0);

    unless ($ENV{ORA_CHARSET_FAIL}) {
        $dbh_utf8 = db_connect(1);
    }
    ($ch, $nch) = $dbh_utf8->selectrow_array("select ch, nch from $table");
    check($ch, $nch, 1);
};

sub check {
    my $ch = shift;
    my $nch = shift;
    my $is_utf8 = shift;

    if ($is_utf8) {
        ok(Encode::is_utf8($ch));
        ok(Encode::is_utf8($nch));
    }
    else {
        ok(!Encode::is_utf8($ch));
        ok(!Encode::is_utf8($nch));
    }

    is($ch, "\xb0", "match char");
    is($nch, "\xb0", "match char");
}

sub db_connect
{
    my $utf8 = shift;

    # Make sure we really are overriding the environment settings.
    my ($charset, $ncharset);
    if ($utf8) {
        set_nls_lang_charset($eight_bit_charset);
        set_nls_nchar($eight_bit_charset);
        $charset = $utf8_charset;
        $ncharset = $utf8_charset;
    }
    else {
        set_nls_lang_charset($utf8_charset);
        set_nls_nchar($utf8_charset);
        $charset = $eight_bit_charset;
        $ncharset = $eight_bit_charset;
    }

    my $dsn = oracle_test_dsn();
    my $dbuser = $ENV{ORACLE_USERID} || 'scott/tiger';

    my $p = {
        AutoCommit => 1,
        PrintError => 0,
        FetchHashKeyName => 'NAME_lc',
        ora_envhp  => 0, # force fresh environment (with current NLS env vars)
    };
    $p->{ora_charset} = $charset if $charset;
    $p->{ora_ncharset} = $ncharset if $ncharset;

    my $dbh = DBI->connect($dsn, $dbuser, '', $p);
    return $dbh;
}

END {
    eval {
        local $dbh->{PrintError} = 0;
      drop_table( $dbh ) if $dbh and not $ENV{'DBD_SKIP_TABLE_DROP'};
    };
}

1;
