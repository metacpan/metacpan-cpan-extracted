use strict;
use warnings;

package My::People;
use base qw(Class::Entity);
sub _object_map { (Department => "My::Departments") }

package My::Departments;
use base qw(Class::Entity);

package main;
use Test::More qw(no_plan);

SKIP : {
  eval { require DBI; require DBD::SQLite };
  skip "skipping tests that require database", 1 if $@;

  my $dbh = DBI->connect("dbi:SQLite:dbname=dbfile");
  ok($dbh, "conecting to dbfile database");

  ok($dbh->do(q{CREATE TABLE People (id, Forename, Surname, Department)}), "creating test data");
  ok($dbh->do(q{CREATE TABLE Departments (id, Name, Description)}), "creating test data");

  ok($dbh->do(q{INSERT INTO Departments (id, Name, Description) VALUES (1, "Engineering", "Getting arthritis")}), "creating test data");
  ok($dbh->do(q{INSERT INTO People (id, Forename, Surname, Department) VALUES (1, "Andrew", "Newman", 1)}), "creating test data");
  ok($dbh->do(q{INSERT INTO People (id, Forename, Surname, Department) VALUES (2, "John", "Newman", 1)}), "creating test data");
  ok($dbh->do(q{INSERT INTO People (id, Forename, Surname, Department) VALUES (3, "Paddy", "Newman", 1)}), "creating test data");

  my $p = My::People->fetch(dbh => $dbh, key => 1);
  isa_ok($p, "My::People");
  isa_ok($p->get_Department, "My::Departments");

  for (My::People->find(dbh => $dbh, where => "Department = 1")) {
    isa_ok($_, "My::People");
    isa_ok($_->get_Department, "My::Departments");
  }

  ok($dbh->disconnect, "disconecting from dbfile");
  ok(unlink("dbfile"), "unlinking test database");
}

