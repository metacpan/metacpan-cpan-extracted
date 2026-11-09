use strict;
use warnings;
use Test::More;

use DBIO::Sybase::Test::Conformance;

# WHY: the declarations of the driver's half of the conformance table are
# checked without a server (karr k97, core ADR 0060): every refusal names a
# case, and the answered table version is a number. The cases themselves run
# in t/102-conformance-ddl-live.t.

my $class = 'DBIO::Sybase::Test::Conformance';

is_deeply [ $class->check_declarations('DDL') ], [],
  'the conformance declarations are whole';

is scalar(@{ $class->cases('DDL') }), 20, 'the DDL table has its twenty cases';

is $class->conformance_answered_through->{DDL}, $class->table_version('DDL'),
  'the driver answers the DDL table as it stands';

# the case's database is named in the DSN, in place or appended; DBD::Sybase
# does not read dbname=
is $class->_dsn_for('dbi:Sybase:host=h;port=5000;database=testdb', 'dbio_cf_1'),
  'dbi:Sybase:host=h;port=5000;database=dbio_cf_1', 'the database of the DSN is swapped';
is $class->_dsn_for('dbi:Sybase:host=h;port=5000', 'dbio_cf_1'),
  'dbi:Sybase:host=h;port=5000;database=dbio_cf_1', '... appended when the DSN names none';

# the runner asks for a quoted name before the case's database exists; the
# answer must not need a connection (a connection made then would land in the
# login's default database, DBD::Sybase only warns)
is $class->conformance_quote_ident(undef, 'base'), 'base', 'a plain name is bare';
is $class->conformance_quote_ident(undef, 'order'), '[order]', '... a keyword is bracketed';

done_testing;
