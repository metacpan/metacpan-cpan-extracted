use strict;
use warnings;
use Test::More;

use DBIO::Sybase::Test::Conformance;

my $class = 'DBIO::Sybase::Test::Conformance';

# WHY: the declarations of the driver's half of the conformance table are
# checked without a server (karr k97, core ADR 0060): every refusal names a
# case, and the answered table version is a number. The cases themselves run
# in t/102-conformance-ddl-live.t.

subtest 'DDL' => sub {
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
};

# WHY: the declarations of the driver's Diff half of the conformance table are
# checked without a server (karr k97, core ADR 0060): every refusal names a
# case, and the answered table version of the area is the one core has. The
# cases themselves run in t/106-conformance-diff-live.t.

subtest 'Diff' => sub {
  is_deeply [ $class->check_declarations('Diff') ], [],
    'the Diff declarations are whole';

  is scalar(@{ $class->cases('Diff') }), 23, 'the Diff table has its twenty-three cases';

  my $through = $class->conformance_answered_through;
  is ref $through, 'HASH', 'conformance_answered_through is a hash, one version per area';
  is $through->{Diff}, $class->table_version('Diff'),
    'the driver answers the Diff table as it stands';
};

# WHY: the declarations of the driver's Bind half of the conformance table are
# checked without a server (karr k97, core ADR 0060): every refusal names a
# case, and the answered table version of the area is the one core has. The
# cases themselves run in t/110-conformance-bind-live.t.

subtest 'Bind' => sub {
  is_deeply [ $class->check_declarations('Bind') ], [],
    'the Bind declarations are whole';

  is scalar(@{ $class->cases('Bind') }), 10, 'the Bind table has its ten cases';

  my $through = $class->conformance_answered_through;
  is ref $through, 'HASH', 'conformance_answered_through is a hash, one version per area';
  is $through->{Bind}, $class->table_version('Bind'),
    'the driver answers the Bind table as it stands';
};

done_testing;
