use strict;
use warnings;
use Test::More;

use DBI;
use DBIO::Oracle::Test::Conformance;

# LIVE (karr k56, core ADR 0060). The cleanup of the conformance class removes
# only what its case created, and the mark of that is the snapshot
# conformance_namespace took; without a mark it does nothing. It never means
# "everything the user owns". A foreign table of the test user, put there
# before any case runs, must survive:
#
#   1. a run of cases that create tables (and a case that is refused),
#   2. a run where conformance_namespace itself throws (the core runner calls
#      conformance_cleanup always, also then),
#   3. a direct conformance_cleanup for a schema whose namespace never ran
#      (an object that appears after the connect is not dropped), and one
#      with a mark (only what the case declared and is newer than the mark
#      is dropped; a newer object that is not the case's stays, and is told),
#   4. a table and an index that appear WHILE the case runs (made by the
#      install itself) survive and are told, the case's own objects go.
#
# CLAIM: the cleanup used to drop every object that was new since the mark,
# so a foreign object made during the case went with it. After: only the
# objects the declaration of the case names go.
#
# The foreign table is dropped by the test itself, also when it fails.

plan skip_all => 'Set $ENV{DBIO_TEST_ORA_DSN}, _USER and _PASS (and have DBD::Oracle) to run this test'
  unless DBIO::Oracle::Test::Conformance->conformance_live_available;

alarm 300;

{
  package T76::Guard;
  sub new { bless { code => $_[1] }, $_[0] }
  sub DESTROY { my $c = delete $_[0]{code}; $c->() if $c }
}
{
  package T76::NoMark;
  use base 'DBIO::Oracle::Test::Conformance';
  my $asked = 0;
  sub asked { $asked }
  sub conformance_namespace { $asked++; die "no mark for you\n" }
  sub conformance_refusals { {} }
}
{ package T76::Direct;  use base 'DBIO::Schema'; }
my $OWN = 'dbio_cf76_own';
{ package T76::Own; use base 'DBIO::Schema'; }
{
  package T76::Own::Result::T;
  use base 'DBIO::Core';
  __PACKAGE__->table('dbio_cf76_own');
  __PACKAGE__->add_columns(id => { data_type => 'integer', is_nullable => 0 });
  __PACKAGE__->set_primary_key('id');
}
T76::Own->register_class(T => 'T76::Own::Result::T');

my $admin = DBI->connect(
  @ENV{qw(DBIO_TEST_ORA_DSN DBIO_TEST_ORA_USER DBIO_TEST_ORA_PASS)},
  { RaiseError => 1, PrintError => 0, AutoCommit => 1 });

my $FOREIGN = "DBIO_CF_FOREIGN_$$";
my $drop_all = sub {
  for my $t ($FOREIGN, "${FOREIGN}_B", "${FOREIGN}_C", "${FOREIGN}_M", $OWN) {
    eval { $admin->do(qq{DROP TABLE "$t" CASCADE CONSTRAINTS PURGE}); 1 };
  }
};
my $guard = T76::Guard->new($drop_all);
END { $drop_all->() if $drop_all and $admin and eval { $admin->ping } }

my $present = sub {
  my ($name) = @_;
  return scalar $admin->selectrow_array(
    q{SELECT COUNT(*) FROM user_tables WHERE table_name = ?}, undef, $name);
};
my $objects = sub {
  my $rows = $admin->selectall_arrayref(
    q{SELECT object_type || ' ' || object_name FROM user_objects
      WHERE object_name NOT LIKE 'BIN$%' ORDER BY 1});
  return [ map { $_->[0] } @$rows ];
};

$drop_all->();
my $start = $objects->();
$admin->do(qq{CREATE TABLE "$FOREIGN" (id NUMBER(10) NOT NULL PRIMARY KEY, note VARCHAR2(20))});
$admin->do(qq{INSERT INTO "$FOREIGN" (id, note) VALUES (7, 'mine')});

my $foreign_intact = sub {
  my ($label) = @_;
  is $present->($FOREIGN), 1, "$label: the foreign table is still there" or return;
  is_deeply $admin->selectall_arrayref(qq{SELECT id, note FROM "$FOREIGN"}),
    [ [ 7, 'mine' ] ], "$label: and so is its row";
};

my $before = $objects->();
my $class  = 'DBIO::Oracle::Test::Conformance';

# 1. cases that create tables, and a refused one
{
  my @r = $class->results('DDL',
    only => [ qw(ddl-foreign-key ddl-default-digit-string ddl-enum-value-apostrophe) ]);
  is scalar(@r), 3, 'the three cases ran';
  like $_->{status}, qr/\A(?:pass|refused|deviation)\z/, "$_->{case}: as declared" for @r;
  $foreign_intact->('after a run of cases');
  is_deeply $objects->(), $before, 'the user owns what it owned before the run';
}

# 2. conformance_namespace throws: the runner calls cleanup all the same
{
  my @r = T76::NoMark->results('DDL', only => [ 'ddl-foreign-key' ]);
  is scalar(@r), 1, 'the case ran';
  is(T76::NoMark->asked(), 1, 'conformance_namespace was asked and threw');
  is $r[0]{status}, 'fail', 'the case failed for want of a mark';
  $foreign_intact->('after a case whose namespace threw');
  is_deeply $objects->(), $before, 'nothing left behind, nothing taken';
}

# 3a. cleanup called directly, for a schema whose namespace never ran
{
  my $schema = $class->conformance_connect('T76::Direct');
  $schema->storage->dbh;
  # an object that appears after the connect; it is not this case's
  $admin->do(qq{CREATE TABLE "${FOREIGN}_B" (id NUMBER(10))});
  ok eval { $class->conformance_cleanup($schema, { name => 'direct' }, undef); 1 },
    'cleanup without a mark does not throw' or diag $@;
  $foreign_intact->('after a cleanup without a mark');
  is $present->("${FOREIGN}_B"), 1,
    'an object created after the connect is not dropped without a mark';
}

# capture what the cleanup tells with diag
my $diag_of = sub {
  my ($code) = @_;
  my $tb = Test::More->builder;
  my $orig = $tb->failure_output;
  my $out = '';
  $tb->failure_output(\$out);
  my $ok = eval { $code->(); 1 };
  my $err = $@;
  $tb->failure_output($orig);
  die $err unless $ok;
  return $out;
};

# 3b. with a mark, only what the case declared and the mark does not hold
#     goes; a newer object that is not the case's stays and is told
{
  my $schema = $class->conformance_connect('T76::Own');
  my $mark = $class->conformance_namespace($schema, { name => 'own' });
  $schema->deploy;
  is $present->($OWN), 1, 'the declared table of the case is installed';
  $admin->do(qq{CREATE TABLE "${FOREIGN}_C" (id NUMBER(10))});
  my $told = $diag_of->(sub {
    ok eval { $class->conformance_cleanup($schema, { name => 'own' }, $mark); 1 },
      'cleanup with a mark runs' or diag $@;
  });
  is $present->($OWN), 0, 'what the case declared is dropped';
  is $present->("${FOREIGN}_C"), 1,
    'a table that is newer than the mark but not the case\'s is not dropped';
  like $told, qr/left alone.*TABLE \Q${FOREIGN}_C\E/s, '... and is told with diag';
  unlike $told, qr/\Q$OWN\E/, '... and what was dropped is not told';
  is $present->("${FOREIGN}_B"), 1, 'what was there before the mark is not dropped either';
  $foreign_intact->('after a cleanup with a mark');
}

# 4. an object that another session makes WHILE the case runs: here the
#    install itself makes a table of the user's, and an index on the table
#    that was there before. Neither is the case's.
{
  package T76::Mid;
  use base 'DBIO::Oracle::Test::Conformance';
  our ($admin, $table, $index, $on);
  sub conformance_refusals { {} }
  sub conformance_install {
    my $class = shift;
    $admin->do(qq{CREATE TABLE "$table" (id NUMBER(10))});
    $admin->do(qq{CREATE INDEX "$index" ON "$on" (note)});
    return $class->SUPER::conformance_install(@_);
  }
}
{
  ($T76::Mid::admin, $T76::Mid::table, $T76::Mid::index, $T76::Mid::on)
    = ($admin, "${FOREIGN}_M", "${FOREIGN}_IX", $FOREIGN);
  my $now = $objects->();
  my @r;
  my $told = $diag_of->(sub {
    @r = T76::Mid->results('DDL', only => [ 'ddl-foreign-key' ]);
  });
  is scalar(@r), 1, 'the case ran';
  is $r[0]{status}, 'pass', 'the case passed, its own objects are dropped'
    or diag $r[0]{message};
  is $present->("${FOREIGN}_M"), 1, 'the table made during the case is still there';
  is scalar $admin->selectrow_array(
      q{SELECT COUNT(*) FROM user_indexes WHERE index_name = ?}, undef, "${FOREIGN}_IX"),
    1, 'so is the index on the table that was there before';
  $foreign_intact->('after the case with a foreign object made during it');
  like $told, qr/TABLE \Q${FOREIGN}_M\E/, 'the table is told with diag';
  like $told, qr/INDEX \Q${FOREIGN}_IX\E/, 'and so is the index';
  is_deeply [ sort @{ $objects->() } ],
    [ sort @$now, "TABLE ${FOREIGN}_M", "INDEX ${FOREIGN}_IX" ],
    'nothing else is new: the case\'s own objects are gone';
}

undef $guard;
is $present->($FOREIGN), 0, 'the foreign table is dropped by the test itself';
is $present->("${FOREIGN}_B"), 0, 'and the other one';

is_deeply $objects->(), $start, 'the user owns what it owned at the start';

done_testing;
