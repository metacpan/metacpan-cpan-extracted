use strict;
use warnings;
use Test::More;

use DBIO::Informix::Introspect::Columns;
use DBIO::Informix::Introspect::Tables;
use DBIO::Informix::Introspect;

# What a real Informix 15.0.1 puts in sysdefaults / systables (karr k20),
# fed to the readers by hand: they must turn it into the model values.

my $md = \&DBIO::Informix::Introspect::Columns::_map_default;

# sysdefaults.default of a literal that is not a character type is
# "<encoded value> <text>"
is $md->(1,  'L', 'AAM 3'),                       3,            'SMALLINT literal';
is $md->(2,  'L', '____.Q -7'),                   -7,           'INTEGER literal, negative';
is $md->(3,  'L', 'AAAAAAAA.D8 1.5000000000000000'), '1.5000000000000000', 'FLOAT literal';
is $md->(5,  'L', 'wQMOAAAA 3.14'),               '3.14',       'DECIMAL literal';
is $md->(7,  'L', 'AACrNw 01/02/2020'),           '01/02/2020', 'DATE literal';
is $md->(17, 'L', 'AAEAAABjAAAAAA 99'),           99,           'INT8 literal';
is $md->(52, 'L', 'AAAAHL6ZGhQ 123456789012'),    '123456789012', 'BIGINT literal';
is $md->(14, 'L', 'xAM   3'),                     3,            'INTERVAL literal, padded';

# character literals and BOOLEAN are stored as they are (no encoded part)
is $md->(0,  'L', 'a b c   '),                    'a b c',      'CHAR literal, padding trimmed, blanks kept';
is $md->(13, 'L', 'x'),                           'x',          'VARCHAR literal';
is $md->(41, 'L', 't'),                           't',          'BOOLEAN literal';

is_deeply $md->(10, 'C', ''), \'CURRENT YEAR TO FRACTION(5)', 'CURRENT without a known column qualifier: the server default';
is_deeply $md->(7,  'T', ''), \'today',                       'TODAY';
is_deeply $md->(0,  'U', ''), \'user',                        'USER is not the empty string';
is_deeply $md->(0,  'S', ''), \'dbservername',                'DBSERVERNAME is not the empty string';
is $md->(0,  'N', ''), undef,                                 'DEFAULT NULL is no default';
is $md->(2,  undef, undef), undef,                            'no sysdefaults row';

# karr k22 -- a DATETIME / INTERVAL literal comes back with the qualifier of
# its column, so the DDL can write it again (the server refuses a bare
# 2026-01-01); collength values as measured on Informix 15.0.1.
is_deeply $md->(10, 'L', 'xxQaAQE 2026-01-01', 2052), \'DATETIME(2026-01-01) YEAR TO DAY',
  'DATETIME literal keeps its qualifier';
is_deeply $md->(10, 'L', 'wwoe 10:30', 1128), \'DATETIME(10:30) HOUR TO MINUTE',
  'DATETIME literal, HOUR TO MINUTE';
is_deeply $md->(14, 'L', 'xAUA    5', 836), \'INTERVAL(5) DAY(3) TO DAY',
  'INTERVAL literal keeps qualifier and leading precision';
is_deeply $md->(14, 'L', 'xgIDAA     2-03', 1538), \'INTERVAL(2-03) YEAR(4) TO MONTH',
  'INTERVAL literal, YEAR(4) TO MONTH';

# karr k22 -- CURRENT keeps the qualifier of its column
is_deeply $md->(10, 'C', '', 3594), \'CURRENT YEAR TO SECOND',  'CURRENT YEAR TO SECOND stays';
is_deeply $md->(10, 'C', '', 4365), \'CURRENT YEAR TO FRACTION(3)', 'CURRENT YEAR TO FRACTION(3) stays';
is_deeply $md->(10, 'C', '', 4879), \'CURRENT YEAR TO FRACTION(5)', 'CURRENT YEAR TO FRACTION(5)';

# karr k22 -- the column types of those defaults are writable too
is(DBIO::Informix::Introspect::Columns::_map_type(14, 836),  'interval day(3) to day',      'interval day(3) to day');
is(DBIO::Informix::Introspect::Columns::_map_type(14, 1538), 'interval year(4) to month',   'interval year(4) to month');
is(DBIO::Informix::Introspect::Columns::_map_type(14, 1642), 'interval hour(2) to second',  'interval hour(2) to second');

# karr k22 -- SERIAL, SERIAL8 and BIGSERIAL are auto-increment columns
{
  package T::ColSth;
  sub new { bless { rows => $_[1] }, $_[0] }
  sub execute { 1 }
  sub finish { 1 }
  sub fetchrow_hashref { shift @{ $_[0]{rows} } }
  package T::ColDbh;
  sub prepare {
    my ($d, $sql) = @_;
    return T::ColSth->new($sql =~ /syscolumns c/ ? [
      map { +{ colname => "c$_->[0]", colno => $_->[0], coltype => $_->[1] + 256, collength => 4 } }
        [1, 6], [2, 18], [3, 53], [4, 2], [5, 17]
    ] : []);
  }
}
{
  my $c = DBIO::Informix::Introspect::Columns->fetch(bless({}, 'T::ColDbh'), 'mydb', { t => {} });
  is_deeply [ map { $_->{is_auto_increment} } @{ $c->{t} } ], [1, 1, 1, 0, 0],
    'serial, serial8, bigserial are auto-increment; integer and int8 are not';
  is_deeply [ map { $_->{data_type} } @{ $c->{t} } ], [qw(serial serial8 bigserial integer int8)],
    'their types stay apart';
}

# systables: user tables are tabid >= 100, whoever owns them. The database
# owner (and the usual connecting user) is 'informix', the owner of the
# catalog too, so the owner cannot tell them apart.
{
  package T::Sth;
  sub new { bless { rows => $_[1] }, $_[0] }
  sub execute { 1 }
  sub fetchrow_hashref { shift @{ $_[0]{rows} } }
  package T::Dbh;
  our @sql;
  sub prepare {
    push @sql, $_[1];
    return T::Sth->new([ { tabname => 'zz', constrname => 'u1_2', owner => 'informix                        ', tabtype => 'T' } ]);
  }
}
my $tables = DBIO::Informix::Introspect::Tables->fetch(bless({}, 'T::Dbh'), 'mydb');
unlike $T::Dbh::sql[0], qr/\bowner\s+(?:NOT\s+)?IN\b/i, 'tables are not filtered by owner';
like   $T::Dbh::sql[0], qr/\btabid\s*>=\s*100\b/,       'catalog tables are told apart by tabid';
is $tables->{zz}{owner}, 'informix', 'CHAR padding of owner is trimmed';

# The compare deploy builds the live model with new(dbh => $dbh) alone. The
# schema is the database name of the catalog qualifier; 'informix' is the
# catalog's owner, not a database (-329 "Database not found" on a server).
{
  package T::Dbh2;
  sub selectrow_array { return ("dbio_test" . (" " x 20)) }   # dbinfo pads
}
is(DBIO::Informix::Introspect->new(dbh => bless({}, 'T::Dbh2'))->schema,
  'dbio_test', 'default schema is the connected database, blanks trimmed');
is(DBIO::Informix::Introspect->new(dbh => bless({}, 'T::Dbh2'), schema => 'other')->schema,
  'other', 'an explicit schema stays');

done_testing;
