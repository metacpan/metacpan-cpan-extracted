use strict;
use warnings;

use DBIx::DataModel::Schema::Generator;

use constant NTESTS  => 7;
use Test::More tests => NTESTS;


SKIP: {
  # v1.38_* of DBD::SQLite required because it has support for foreign_key_info
  eval "use DBD::SQLite 1.38; 1"
    or skip "DBD::SQLite 1.38 does not seem to be installed", NTESTS;

  my $dbh = DBI->connect('dbi:SQLite:dbname=:memory:', '', '', {
    RaiseError => 1,
    AutoCommit => 1,
    sqlite_allow_multiple_statements => 1,
  });

  $dbh->do(q{
    PRAGMA foreign_keys = ON;
    CREATE TABLE employee (
      emp_id        INTEGER PRIMARY KEY,
      emp_name      TEXT
    );
    CREATE TABLE department (
      dpt_id        INTEGER PRIMARY KEY,
      dpt_name      TEXT
    );
    CREATE TABLE activity (
      act_id        INTEGER PRIMARY KEY,
      emp_id        INTEGER NOT NULL REFERENCES employee(emp_id),
      dpt_id        INTEGER NOT NULL REFERENCES department(dpt_id),
      supervisor    INTEGER          REFERENCES employee(emp_id)
    );
    CREATE TABLE activity_event (
      act_event_id  INTEGER PRIMARY KEY,
      act_id        INTEGER NOT NULL REFERENCES activity(act_id)
                                     ON DELETE CASCADE,
      event_text    TEXT
    );
    CREATE TABLE employee_status (
      emp_id_status INTEGER PRIMARY KEY,
      emp_id        INTEGER NOT NULL REFERENCES employee(emp_id),
      status_name   TEXT
    );
   });

  my $generator = DBIx::DataModel::Schema::Generator->new(
    -schema => 'Test::DBIDM::Schema::Generator'
   );

  $generator->parse_DBI($dbh);
  my $perl_code = $generator->perl_code;

  like($perl_code, qr{Table\(qw/Activity},             "Table Activity");
  like($perl_code, qr{Table\(qw/ActivityEvent},        "Table ActivityEvent");
  like($perl_code, qr{Composition.*?activity_events}s, "Composition");
  like($perl_code, qr{Association.*?activit(ie|y)s}s,  "Association");
  like($perl_code, qr{employee_2}s,                    "avoid duplicate associations");

#  diag($perl_code);


  # Generate proper schema even if there is no association
  $dbh = DBI->connect('dbi:SQLite:dbname=:memory:', '', '', {
    RaiseError => 1,
    AutoCommit => 1,
    sqlite_allow_multiple_statements => 1,
  });
  $dbh->do(q{
    CREATE TABLE foo (foo1, foo2);
    CREATE TABLE bar (bar1, bar2, bar3);
  });
  $generator = DBIx::DataModel::Schema::Generator->new(
    -schema => 'Test::DBIDM::Schema::Generator2'
   );
  $generator->parse_DBI($dbh);
  $perl_code = $generator->perl_code;
  like($perl_code, qr{Table\(qw/Foo},             "Table foo");
  like($perl_code, qr{Table\(qw/Bar},             "Table bar");
}


