use strict;
use warnings;

use Test::More;
use DBI;
use DBIO::Schema;
use DBIO::Oracle::Deploy;
use DBIO::Oracle::Storage;

# LIVE (karr k66). The storage declares _ddl_sql_dialect 'oracle', and core's
# splitter keeps the semicolon after END of a PL/SQL unit. What the server says
# about the objects that come out of Deploy->_execute_ddl, in ALL_OBJECTS.STATUS
# (a unit created without its semicolon is INVALID, ORA-24344): the trigger of
# the install DDL, and a function, a procedure, a package with its body, an
# anonymous block and a COMPOUND TRIGGER written by hand. t/97 is the offline
# half. All names carry the prefix DBIO_K66_ and are dropped at the end.

my ($dsn, $user, $pass) = @ENV{map { "DBIO_TEST_ORA_${_}" } qw/DSN USER PASS/};

plan skip_all => 'Set $ENV{DBIO_TEST_ORA_DSN}, _USER and _PASS to run this test'
  unless $dsn && defined $user && defined $pass;

{
  package T::K66::Item;
  use base 'DBIO::Core';
  __PACKAGE__->table('DBIO_K66_ITEM');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer', is_auto_increment => 1 },
    name => { data_type => 'varchar', size => 50 },
  );
  __PACKAGE__->set_primary_key('id');
}

{
  package T::K66::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('Oracle');
  __PACKAGE__->register_class(Item => 'T::K66::Item');
}

my $schema = T::K66::Schema->connect($dsn, $user, $pass, { AutoCommit => 1, RaiseError => 1 });
my $dbh    = $schema->storage->dbh;
my $deploy = DBIO::Oracle::Deploy->new(schema => $schema);

my @cleanup = (
  q{DROP FUNCTION DBIO_K66_JF},
  q{DROP TRIGGER DBIO_K66_CT},
  q{DROP PACKAGE DBIO_K66_PKG},
  q{DROP PROCEDURE DBIO_K66_PROC},
  q{DROP FUNCTION DBIO_K66_FUNC},
  q{DROP TABLE DBIO_K66_CTAB PURGE},
  q{DROP TABLE "DBIO_K66_ITEM" PURGE},
  q{DROP SEQUENCE "DBIO_K66_ITEM_id_seq"},
);
sub cleanup {
  return unless $dsn;   # END runs after a skip_all as well
  my $c = DBI->connect($dsn, $user, $pass, { RaiseError => 0, PrintError => 0 }) or return;
  $c->do($_) for @cleanup;
  $c->disconnect;
}
cleanup();
END { cleanup() }

sub status {
  my ($name) = @_;
  my ($st) = $dbh->selectrow_array(
    q{SELECT status FROM user_objects WHERE object_name = ? AND object_type NOT LIKE '%BODY'}, undef, $name);
  return $st;
}

local $SIG{__WARN__} = sub { warn @_ unless $_[0] =~ /non-transactional|transactional DDL/i };

# the trigger of the install DDL
$deploy->_execute_ddl($dbh, $deploy->_install_ddl);
my ($trg) = $dbh->selectrow_array(
  q{SELECT trigger_name FROM user_triggers WHERE table_name = 'DBIO_K66_ITEM'});
ok defined $trg, 'the install DDL made a trigger';
is status($trg), 'VALID', 'the trigger of the install DDL is VALID';
is $dbh->selectrow_array(q{SELECT COUNT(*) FROM user_errors WHERE name = ?}, undef, $trg), 0,
  '... and has no compile errors';

# hand-written PL/SQL through the same path
my @units = (
  [ DBIO_K66_FUNC => q{CREATE OR REPLACE FUNCTION DBIO_K66_FUNC RETURN NUMBER IS BEGIN RETURN 42; END;} ],
  [ DBIO_K66_PROC => q{CREATE OR REPLACE PROCEDURE DBIO_K66_PROC IS x NUMBER; BEGIN x := 1; END;} ],
  [ DBIO_K66_PKG  => join ";\n",
      q{CREATE OR REPLACE PACKAGE DBIO_K66_PKG IS FUNCTION f RETURN NUMBER},
      q{END DBIO_K66_PKG},
      q{CREATE OR REPLACE PACKAGE BODY DBIO_K66_PKG IS FUNCTION f RETURN NUMBER IS BEGIN RETURN 1; END f},
      q{END DBIO_K66_PKG;} ],
);
for my $u (@units) {
  $deploy->_execute_ddl($dbh, $u->[1]);
  is status($u->[0]), 'VALID', "$u->[0] is VALID";
}
is $dbh->selectrow_array(q{SELECT status FROM user_objects WHERE object_name = 'DBIO_K66_PKG' AND object_type = 'PACKAGE BODY'}),
  'VALID', 'the package body is VALID';

$deploy->_execute_ddl($dbh, q{CREATE TABLE DBIO_K66_CTAB (id NUMBER, n NUMBER)});

$deploy->_execute_ddl($dbh, q{BEGIN INSERT INTO DBIO_K66_CTAB (id) VALUES (1); END;});
is $dbh->selectrow_array(q{SELECT COUNT(*) FROM DBIO_K66_CTAB}), 1, 'the anonymous block ran';

$deploy->_execute_ddl($dbh, <<'SQL');
CREATE OR REPLACE TRIGGER DBIO_K66_CT
FOR INSERT ON DBIO_K66_CTAB COMPOUND TRIGGER
  BEFORE EACH ROW IS BEGIN
    :NEW.n := 7;
  END BEFORE EACH ROW;
END DBIO_K66_CT;
SQL
is status('DBIO_K66_CT'), 'VALID', 'the COMPOUND TRIGGER is VALID';
$dbh->do(q{INSERT INTO DBIO_K66_CTAB (id) VALUES (2)});
is $dbh->selectrow_array(q{SELECT n FROM DBIO_K66_CTAB WHERE id = 2}), 7, '... and fires';

# a Java call spec ends in a semicolon of its own, no PL/SQL block: measured on
# 23ai Free (JAVAVM removed, the spec is still compiled): VALID with the
# semicolon the splitter keeps, INVALID without it. A C call spec could not be
# measured: CREATE LIBRARY answers ORA-01031 for the test user.
$deploy->_execute_ddl($dbh,
  q{CREATE OR REPLACE FUNCTION DBIO_K66_JF (s VARCHAR2) RETURN VARCHAR2 AS LANGUAGE JAVA NAME 'java.lang.String.valueOf(java.lang.String) return java.lang.String';});
is status('DBIO_K66_JF'), 'VALID', 'a Java call spec is VALID';

done_testing;
