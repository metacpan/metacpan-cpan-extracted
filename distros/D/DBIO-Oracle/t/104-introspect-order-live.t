use strict;
use warnings;
use utf8;

use Test::More;
use DBI;
use DBIO::Optional::Dependencies ();
use DBIO::Oracle::Introspect;

# LIVE. The model lists its foreign keys of a table and the views a view rests
# on in binary order by name, whatever NLS_SORT the session has. The names
# below are ones GERMAN puts in another order than BINARY (a_x, aB, Ab, _z, an
# umlaut); the introspection runs on a connection that was set to GERMAN with
# ALTER SESSION, and the order of the answer is held against Perl's `sort`, the
# order of the characters. t/103-introspect-order.t pins the text of the
# ORDER BYs; this is the server's answer. (Run it under
# NLS_LANG=GERMAN_GERMANY.AL32UTF8 as well: the order must not change.)
#
# Tables, indexes and keys come back in hashes, where an order of reading is
# not visible; the arrays of the model are: the foreign keys of a table, and
# depends_on of a view.

my ($dsn, $user, $pass) = @ENV{map { "DBIO_TEST_ORA_${_}" } qw/DSN USER PASS/};

plan skip_all => 'Set $ENV{DBIO_TEST_ORA_DSN}, _USER and _PASS to run this test'
  unless $dsn && defined $user && defined $pass;

plan skip_all => 'Test needs '
  . DBIO::Optional::Dependencies->req_missing_for('test_rdbms_oracle')
  unless DBIO::Optional::Dependencies->req_ok_for('test_rdbms_oracle');

alarm 300;

sub connect_plain {
  return DBI->connect($dsn, $user, $pass, {
    RaiseError => 1, PrintError => 0, AutoCommit => 1,
    ora_charset => 'AL32UTF8', ora_ncharset => 'AL32UTF8',
  });
}

my $admin = connect_plain();
my $dbh   = connect_plain();
$dbh->do(q{ALTER SESSION SET NLS_SORT = GERMAN});

my ($SCHEMA) = $admin->selectrow_array('SELECT USER FROM DUAL');

# the suffixes of the names; the common prefix keeps the relative order
my @SUFFIX = ('a_x', 'aB', 'Ab', '_z', 'Äb');

sub wipe {
  for my $sql (
    ( map { qq{DROP VIEW "T104_V_$_"} } @SUFFIX ),
    'DROP VIEW T104_TOP',
    'DROP TABLE T104_C CASCADE CONSTRAINTS PURGE',
    'DROP TABLE T104_P CASCADE CONSTRAINTS PURGE',
  ) {
    eval { $admin->do($sql); 1 } or $@ =~ /ORA-(?:00942|04043)\b/ or die $@;
  }
}

wipe();
END { wipe() if $admin && $admin->{Active} }

$admin->do('CREATE TABLE T104_P (id NUMBER PRIMARY KEY)');
$admin->do('CREATE TABLE T104_C (' . join(', ', map { "c$_ NUMBER" } 0 .. $#SUFFIX) . ')');
$admin->do(qq{ALTER TABLE T104_C ADD CONSTRAINT "T104_FK_$SUFFIX[$_]" FOREIGN KEY (c$_) REFERENCES T104_P (id)})
  for 0 .. $#SUFFIX;
$admin->do(qq{CREATE VIEW "T104_V_$_" AS SELECT id FROM T104_P}) for @SUFFIX;
$admin->do('CREATE VIEW T104_TOP AS SELECT '
  . join(', ', map { qq{v$_.id AS c$_} } 0 .. $#SUFFIX) . ' FROM '
  . join(', ', map { qq{"T104_V_$SUFFIX[$_]" v$_} } 0 .. $#SUFFIX));

my @fk_binary   = sort map { "T104_FK_$_" } @SUFFIX;
my @view_binary = sort map { "T104_V_$_" } @SUFFIX;

# The fixture means something only if GERMAN really sorts these differently.
my @fk_german = map { $_->[0] } @{ $dbh->selectall_arrayref(
  q{SELECT constraint_name FROM user_constraints WHERE table_name = 'T104_C' AND constraint_type = 'R' ORDER BY constraint_name}) };
isnt join(',', @fk_german), join(',', @fk_binary),
  'the session sorts the names differently from BINARY (the names are a test of something)';

my $model = DBIO::Oracle::Introspect->new(dbh => $dbh, schema => $SCHEMA)->model;

is_deeply [ map { $_->{constraint_name} } @{ $model->{foreign_keys}{T104_C} } ], \@fk_binary,
  'the foreign keys of a table come in binary order by name under NLS_SORT=GERMAN';

is_deeply $model->{views}{T104_TOP}{depends_on}, \@view_binary,
  'the views a view rests on come in binary order by name under NLS_SORT=GERMAN';

is $dbh->selectrow_array(q{SELECT value FROM nls_session_parameters WHERE parameter = 'NLS_SORT'}),
  'GERMAN', 'the session keeps its NLS_SORT';

wipe();
$dbh->disconnect;
$admin->disconnect;

done_testing;
