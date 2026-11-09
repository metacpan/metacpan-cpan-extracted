use strict;
use warnings;

use Test::More;

use DBIO::Optional::Dependencies ();
use DBIO::Test::Schema;
use DBIO::Storage::DBI;
use DBIO::Informix::Storage;

# ADR 0039 (karr k23) -- _set_operation_keyword($op) spells each of
# DBIO::ResultSet's six set operations or refuses it. Measured against
# Informix 15.0.1 (the live block below runs the same statements):
#
#   UNION, UNION ALL, INTERSECT   accepted, ANSI spelling
#   EXCEPT                        accepted (MINUS is the synonym), ANSI
#                                 spelling
#   INTERSECT ALL, EXCEPT ALL     SQL -201, a syntax error: the engine has
#                                 the distinct forms only
#
# So four operations are core's base map, left alone, and two are refused.
# The refusal is unconditional: this hook is static (ADR 0039 section 7) and
# so cannot ask which release it talks to, and no release is known to have
# the ALL forms of INTERSECT and EXCEPT.

sub informix_schema {
  my $schema = DBIO::Test::Schema->clone;
  $schema->storage_type('+DBIO::Informix::Storage');
  return $schema->connect(@_);
}

my $schema  = informix_schema('dbi:Informix:ixdb@ixserver');
my $storage = $schema->storage;

my %spelled = (
  union         => 'UNION',
  union_all     => 'UNION ALL',
  intersect     => 'INTERSECT',
  except        => 'EXCEPT',
);

for my $op (sort keys %spelled) {
  is ($storage->_set_operation_keyword($op), $spelled{$op},
    "$op is spelled $spelled{$op}");
}

for my $op (qw(intersect_all except_all)) {
  my $keyword = eval { $storage->_set_operation_keyword($op) };
  my $err     = $@;

  is ($keyword, undef, "$op produces no keyword");

  like ($err, qr/Informix cannot express the set operation '$op'/,
    '... the refusal names the engine and the operation');

  like ($err, qr/-201/,
    '... says what the server answers, so the claim can be checked');

  like ($err, qr/INTERSECT and EXCEPT.*distinct|distinct.*INTERSECT and EXCEPT/s,
    '... says what the engine does have, the distinct forms');
}

isnt (
  DBIO::Informix::Storage->can('_set_operation_keyword'),
  DBIO::Storage::DBI->can('_set_operation_keyword'),
  'the hook is a real override of core\'s, by coderef identity',
);

{
  my $keyword = eval { $storage->_set_operation_keyword('exept') };
  is ($keyword, undef, 'a misspelled operation produces no keyword');
  like ($@, qr/Unknown set operation 'exept'/,
    '... it reaches core\'s throw through next::method: an unknown name is a '
  . 'core programming error, not an Informix fact');
}

{
  my $rs    = $schema->resultset('Artist')->search({ name => 'foo' });
  my $other = $schema->resultset('Artist')->search({ rank => 13 });

  my ($sql, @bind) = @{ ${ $rs->except($other)->as_query } };
  like ($sql, qr/WHERE \( "name" = \? \)\s+EXCEPT\s+SELECT\b/,
    'except joins its two operands with EXCEPT');
  is_deeply ([ map { $_->[1] } @bind ], [ 'foo', 13 ],
    '... binds in left-to-right order');

  my $err_rs = eval { $rs->except_all($other) };
  is ($err_rs, undef, 'ResultSet::except_all refuses through the same hook');
  like ($@, qr/Informix cannot express/,
    '... with this driver\'s message, not a -201 from the server');

  ok (! $storage->connected,
    '... at query-build time and without a connection');
}

# ------------------------------------------------------------------- live

SKIP: {
  my ($dsn, $user, $pass) = @ENV{map { "DBIO_TEST_INFORMIX_$_" } qw/DSN USER PASS/};

  skip 'Set $ENV{DBIO_TEST_INFORMIX_DSN}, _USER and _PASS to run the live half', 8
    unless $dsn;

  skip 'Test needs ' . DBIO::Optional::Dependencies->req_missing_for('test_rdbms_informix'), 8
    unless DBIO::Optional::Dependencies->req_ok_for('test_rdbms_informix');

  {
    package T::SetRow;
    use base 'DBIO::Core';
    __PACKAGE__->table('naehte_setop');
    __PACKAGE__->add_columns(
      id   => { data_type => 'integer' },
      kind => { data_type => 'integer' },
    );
    __PACKAGE__->set_primary_key('id');

    package T::SetSchema;
    use base 'DBIO::Schema';
    __PACKAGE__->storage_type('+DBIO::Informix::Storage');
    __PACKAGE__->register_class(Row => 'T::SetRow');
  }

  my $live = T::SetSchema->connect($dsn, $user, $pass);
  my $dbh  = $live->storage->dbh;

  eval { $dbh->do('DROP TABLE naehte_setop') };
  $dbh->do('CREATE TABLE naehte_setop (id INTEGER PRIMARY KEY, kind INTEGER)');
  END { local $@; eval { $dbh->do('DROP TABLE naehte_setop') } if $dbh }

  # ids 1,2 are kind 1; ids 2,3 are kind 2 (2 appears in both operands)
  $dbh->do('INSERT INTO naehte_setop VALUES (?, ?)', undef, @$_)
    for [1, 1], [2, 1], [3, 2];

  my $rs = $live->resultset('Row');
  my $left  = $rs->search({ id => { -in => [1, 2] } })->columns(['id']);
  my $right = $rs->search({ id => { -in => [2, 3] } })->columns(['id']);

  my $ids = sub { join ',', sort { $a <=> $b } map { $_->id } $_[0]->all };

  is ($ids->($left->union($right)),         '1,2,3', 'live: union');
  is ($ids->($left->union_all($right)),     '1,2,2,3', 'live: union_all keeps the duplicate');
  is ($ids->($left->intersect($right)),     '2',     'live: intersect');
  is ($ids->($left->except($right)),        '1',     'live: except');

  # The two refused operations really are syntax errors on the server: this
  # is the measurement the refusal text quotes.
  for my $op ('INTERSECT ALL', 'EXCEPT ALL') {
    my $ok = eval {
      $dbh->prepare("SELECT id FROM naehte_setop WHERE id < 3 $op SELECT id FROM naehte_setop WHERE id > 1");
      1;
    };
    ok (!$ok, "live: the server refuses $op");
    like ("$@", qr/-201/, '... with -201, a syntax error');
  }
}

done_testing;
