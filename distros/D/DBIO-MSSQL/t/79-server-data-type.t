use strict;
use warnings;

use Test::More;

use DBI;
use DBIO::MSSQL::Storage;
use DBIO::MSSQL::Storage::ODBC;
use DBIO::MSSQL::Storage::Sybase;

# OFFLINE (karr k47, k58). Both access paths decide what to do with a value
# by the type its column has ON THE SERVER, not by the portable name it is
# declared with: DBIO::MSSQL::DDL deploys 'text' as NVARCHAR(MAX), 'varchar'
# and 'string' as NVARCHAR(n), 'char' as NCHAR(n) (DBIO::MSSQL::Adapter is the
# one table, there is no second one here). The question is one function,
# DBIO::MSSQL::Storage::_server_data_type, answered from that same DDL code.
# What a server does with the values: t/80-server-type-live.t.

my $base   = DBIO::MSSQL::Storage->new(undef);
my $odbc   = DBIO::MSSQL::Storage::ODBC->new(undef);
my $sybase = DBIO::MSSQL::Storage::Sybase->new(undef);

# ------------------------------------------- the type a column has on the server

my @server = (
  [ { data_type => 'text' },                          'nvarchar(max)' ],
  [ { data_type => 'TEXT' },                          'nvarchar(max)' ],
  [ { data_type => 'text', size => 100 },             'nvarchar(max)' ],
  [ { data_type => 'varchar' },                       'nvarchar' ],
  [ { data_type => 'varchar', size => 100 },          'nvarchar(100)' ],
  [ { data_type => 'varchar', size => -1 },           'nvarchar(max)' ],
  [ { data_type => 'string', size => 40 },            'nvarchar(40)' ],
  [ { data_type => 'char', size => 10 },              'nchar(10)' ],
  [ { data_type => 'nvarchar', size => [ 30 ] },      'nvarchar(30)' ],
  [ { data_type => 'ntext' },                         'ntext' ],
  [ { data_type => 'varchar(max)' },                  'varchar(max)' ],
  [ { data_type => 'varchar(50)' },                   'varchar(50)' ],
  [ { data_type => 'char(10)' },                      'char(10)' ],
  [ { data_type => 'xml' },                           'xml' ],
  [ { data_type => 'integer' },                       'bigint' ],
  [ { data_type => 'varchar', size => 0 },            'varchar' ],    # a size the DDL refuses: as declared
);

is $base->_server_data_type($_->[0]), $_->[1],
  "$_->[0]{data_type}" . ( defined $_->[0]{size} ? " (size " . ( ref $_->[0]{size} ? "[@{ $_->[0]{size} }]" : $_->[0]{size} ) . ')' : '' )
. " is $_->[1] on the server"
  for @server;

is $base->_server_data_type('text'), 'nvarchar(max)', 'a bare data type is asked the same way';
is $base->_server_data_type(undef), undef, 'no data type, no answer';

# ------------------------------------------------ DBD::ODBC: which binds are national

my $WLONG = DBI::SQL_WLONGVARCHAR();

is $odbc->bind_attribute_by_data_type($_), $WLONG, "ODBC: a value for '$_' is bound as SQL_WLONGVARCHAR"
  for qw(text varchar string char nchar nvarchar ntext nvarchar(max)), 'national char(10)';

is $odbc->bind_attribute_by_data_type($_), undef,
  "ODBC: a value for '$_', the server's own VARCHAR, is bound without a type"
  for 'varchar(50)', 'varchar(max)', 'char(10)';

is $odbc->bind_attribute_by_data_type($_), DBI::SQL_LONGVARBINARY(),
  "ODBC: '$_' is still SQL_LONGVARBINARY (k50: a binary type is decided first)"
  for qw(varbinary binary image blob);

# ------------------------------------------ DBD::Sybase: which columns are guarded

my %kind = (
  text           => 'nvarchar_max',
  'varchar(max)' => 'varchar_max',
  'nvarchar(max)'=> 'nvarchar_max',
  ntext          => 'ntext',
  varbinary      => 'binary',
  image          => 'binary',
  'varchar(50)'  => undef,
  xml            => undef,
  integer        => undef,
);
is $sybase->_long_column_kind({ data_type => $_ }), $kind{$_},
  "Sybase: a '$_' column is " . ( $kind{$_} // 'not subject to TEXTSIZE' )
  for sort keys %kind;

is $sybase->_long_column_kind({ data_type => 'varchar', size => -1 }), 'nvarchar_max',
  "Sybase: a 'varchar' of size -1 is an NVARCHAR(MAX) on the server";
is $sybase->_long_column_kind({ data_type => 'varchar', size => 100 }), undef,
  "Sybase: a 'varchar' of size 100 is an NVARCHAR(100): not subject to TEXTSIZE";
is $sybase->_long_column_kind({ data_type => 'nvarchar', size => [ -1 ] }), 'nvarchar_max',
  'Sybase: a size given as [-1] is (max) too';
is $sybase->_long_column_kind({}), undef, 'Sybase: no data type, no kind';

# The statement of each kind: the CASE returns the column itself (a NULL is NULL
# whatever CONCAT_NULL_YIELDS_NULL says), of the type the column is.
{
  my $guard = sub { $sybase->_guarded_long_column('me.c', { data_type => 'x' }, shift) };

  like $guard->('nvarchar_max'),
    qr/\ACASE WHEN DATALENGTH\(\S+\) > \@\@TEXTSIZE THEN CONVERT\(NVARCHAR\(MAX\), CONVERT\(INT, .*\)\) ELSE \S+ END\z/s,
    'an NVARCHAR(MAX): the failing branch is an NVARCHAR(MAX), the ELSE is the column';
  like $guard->('varchar_max'),
    qr/\ACASE WHEN DATALENGTH\(\S+\) > \@\@TEXTSIZE THEN CONVERT\(VARCHAR\(MAX\), CONVERT\(INT, .*\)\) ELSE \S+ END\z/s,
    'a VARCHAR(MAX): the failing branch is a VARCHAR(MAX), the ELSE is the column';
  unlike $guard->($_), qr/ \+ CASE|ELSE ''/, "$_: no concatenation, no '' (a NULL stays NULL)"
    for qw(nvarchar_max varchar_max);
  like $guard->('ntext'), qr/ELSE CAST\(\S+ AS NVARCHAR\(MAX\)\) END\z/,
    'an NTEXT is cast to NVARCHAR(MAX) (a CASE cannot return an NTEXT)';
}

done_testing;
