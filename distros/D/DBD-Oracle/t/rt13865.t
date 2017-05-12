# $Id$
use strict;

use DBI;
use DBD::Oracle;

use Test::More;

use lib 't';
require 'nchar_test_lib.pl';

my $dbh = db_handle() or plan skip_all => "can't connect to database";

my %priv = map { $_ => 1 } get_privs( $dbh );

unless ( $priv{'CREATE TABLE'} ) {
    plan skip_all => q{requires permissions 'CREATE TABLE'};
}

plan tests => 9;

$dbh->do( 'DROP TABLE RT13865' );

$dbh->do( <<'END_SQL' ) or die $dbh->errstr;
CREATE TABLE RT13865(
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

my $col_h = $dbh->column_info( undef, undef, 'RT13865', 'COL_INTEGER' );

is $col_h->fetchrow_hashref->{COLUMN_SIZE} => 38,
    "INTEGER is alias for NUMBER(38)";

$col_h = $dbh->column_info( undef, undef, 'RT13865', 'COL_NUMBER_37' );
is $col_h->fetchrow_hashref->{COLUMN_SIZE} => 37,
    "NUMBER(37)";

$col_h = $dbh->column_info( undef, undef, 'RT13865', 'COL_NUMBER' );
cmp_ok $col_h->fetchrow_hashref->{COLUMN_SIZE}, '>', 0,
    "NUMBER";

$col_h = $dbh->column_info( undef, undef, 'RT13865', 'COL_VC2' );
is $col_h->fetchrow_hashref->{COLUMN_SIZE} => 67,
    "VARCHAR(67)";

$col_h = $dbh->column_info( undef, undef, 'RT13865', 'COL_VC2_69CHAR' );
is $col_h->fetchrow_hashref->{COLUMN_SIZE} => 69,
    "VARCHAR(69)";

$col_h = $dbh->column_info( undef, undef, 'RT13865', 'COL_NVC2' );
is $col_h->fetchrow_hashref->{COLUMN_SIZE} => 69,
    "NVARCHAR2(69)";

$col_h = $dbh->column_info( undef, undef, 'RT13865', 'COL_NC' );
is $col_h->fetchrow_hashref->{COLUMN_SIZE} => 69,
    "NCHAR(69)";

$col_h = $dbh->column_info( undef, undef, 'RT13865', 'COL_CHAR' );
is $col_h->fetchrow_hashref->{COLUMN_SIZE} => 67,
    "CHAR(67)";

$col_h = $dbh->column_info( undef, undef, 'RT13865', 'COL_CHAR_69CHAR' );
is $col_h->fetchrow_hashref->{COLUMN_SIZE} => 69,
    "CHAR(69)";

$dbh->do( 'DROP TABLE RT13865' );

# utility functions

sub get_privs  {
    my $dbh = shift;

    my $sth = $dbh->prepare( 'SELECT PRIVILEGE from session_privs' );
    $sth->execute;

    return map { $_->[0] } @{ $sth->fetchall_arrayref };
}
