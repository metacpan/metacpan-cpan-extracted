#!perl

use strict;
use warnings;

use Test::More;
use Symbol qw( delete_package );

use lib 't/lib';

require_ok('DBDOracleTestLib')
  or BAIL_OUT 'DBDOracleTestLib require problem... impossible to proceed';

my @functions = qw/
    db_handle extra_wide_rows long_test_cols
    oracle_test_dsn show_test_data test_data
    select_test_count select_rows
    cmp_ok_byte_nice show_db_charsets
    db_ochar_is_utf db_nchar_is_utf
    client_ochar_is_utf8 client_nchar_is_utf8
    set_nls_nchar set_nls_lang_charset
    insert_test_count nice_string
    create_table table drop_table insert_rows dump_table
    force_drop_table
/;

can_ok('DBDOracleTestLib', @functions);

sub is_exported_by {
    my ($imports, $expect, $msg) = @_;
    delete_package 'Clean';
    eval '
        package Clean;
        DBDOracleTestLib->import(@$imports);
        ::is_deeply([sort keys %Clean::], [sort @$expect], $msg);
    ' or die "# $@";
}

is_exported_by([], [], 'nothing is exported by default');

done_testing;

1;
