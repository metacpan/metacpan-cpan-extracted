#!perl

use strict;
use warnings;

use lib 't/lib';
use DBDOracleTestLib qw/ db_handle table drop_table force_drop_table /;

use DBI;
use DBD::Oracle;

use Test::More;

my $dbh = db_handle()
  or plan skip_all => q|Can't connect to database|;

my %priv = map { $_ => 1 } get_privs($dbh);

unless ( $priv{'CREATE TABLE'} ) {
    plan skip_all => q{requires permissions 'CREATE TABLE'};
}

my $table = table('rt13865__drop_me');
force_drop_table($dbh, $table);

my $create_sql = <<"END_SQL";
CREATE TABLE $table(
    COL_INTEGER INTEGER,
    COL_NUMBER NUMBER,
    COL_NUMBER_37 NUMBER(37),
    COL_DECIMAL NUMBER(9,2),
    COL_FLOAT FLOAT(126),
    COL_VC2   VARCHAR2(67),
    COL_VC2_69CHAR  VARCHAR2(69 CHAR),
    COL_NVC2  NVARCHAR2(69),
    COL_NC    NCHAR(69),
    COL_CHAR  CHAR(67),
    COL_CHAR_69CHAR  CHAR(69 CHAR)
)
END_SQL

my @tests = (
    {
        col  => 'COL_INTEGER',
        size => 38,
        cmp  => '==',
        name => 'INTEGER is alias for NUMBER(38)'
    },
    {
        col  => 'COL_NUMBER_37',
        size => 37,
        cmp  => '==',
        name => 'NUMBER(37)'
    },
    {
        col  => 'COL_NUMBER',
        size => 0,
        cmp  => '>',
        name => 'NUMBER'
    },
    {
        col  => 'COL_VC2',
        size => 67,
        cmp  => '==',
        name => 'VARCHAR2(67)'
    },
    {
        col  => 'COL_VC2_69CHAR',
        size => 69,
        cmp  => '==',
        name => 'VARCHAR2(69)'
    },
    {
        col  => 'COL_NVC2',
        size => 69,
        cmp  => '==',
        name => 'NVARCHAR2(69)'
    },
    {
        col  => 'COL_NC',
        size => 69,
        cmp  => '==',
        name => 'NCHAR(69)'
    },
    {
        col  => 'COL_CHAR',
        size => 67,
        cmp  => '==',
        name => 'CHAR(67)'
    },
    {
        col  => 'COL_CHAR_69CHAR',
        size => 69,
        cmp  => '==',
        name => 'CHAR(69)'
    },
);    # @tests

ok( $dbh->do($create_sql), "Create database: $table" )
  or die $dbh->errstr;

for my $test (@tests) {

    my $col_h = $dbh->column_info( undef, undef, uc($table), $test->{col} );

    # if column_info() returns undef, then the driver doesnt support column_info. DBD::Oracle should support it.
    ok(
        $col_h,
        sprintf(
            'column_info() returns something for test: %s', $test->{name}
        )
    ) or next;
    cmp_ok( ref $col_h, 'eq', 'DBI::st',
        sprintf( 'returned object is correct for test: %s', $test->{name} ) );

# if there is no row, then the table/column couldnt be found... this should not happen either
    my $row = $col_h->fetchrow_hashref;
    cmp_ok(
        ref $row,
        'eq', 'HASH',
        sprintf(
'column/table now found - fetchrow_hashref returned a hash for test: %s',
            $test->{name} )
    ) or next;

    # this is the actual test, everything above it sanity checking / pre-diagnosis
    cmp_ok( $row->{COLUMN_SIZE}, $test->{cmp}, $test->{size}, $test->{name} );

}

drop_table($dbh, $table);

# utility functions

sub get_privs {
    my $dbh = shift;

    my $sth = $dbh->prepare('SELECT PRIVILEGE from session_privs');
    $sth->execute;

    return map { $_->[0] } @{ $sth->fetchall_arrayref };
}

done_testing();
