#!/usr/bin/env perl
# t/51-finish-without-result.t -- a statement the engine refuses is an
# exception, not the end of the process (karr k38).
#
# WHY this matters: a populate in void context is the bulk insert, and a row
# the engine refuses -- a key that is taken -- is the ordinary way for one to
# fail. Core runs it through one statement handle and calls finish on that
# handle whatever happened, as cleanup code does. DBD::DuckDB 0.16 keeps a
# handle's result only once an execute has succeeded, and its finish hands
# libduckdb that result without looking: where there is none, NULL arrives in
# duckdb_destroy_result and the process dies of a segmentation fault. No
# exception, nothing to catch, the transaction and whatever the program had
# not written out yet gone with it.
#
# It takes a handle on which NO execute has succeeded, so it is the FIRST row
# of the populate that has to be refused: the engine then answers every
# further row of the batch with "transaction is aborted", and the handle
# reaches finish empty. A populate whose first row goes in and whose second is
# refused was an exception all along. The same finish is reached by hand
# through dbh_do: after an execute that was refused, a second time, or on a
# handle that was never executed.
#
# DBIO::DuckDB::Storage gives such a handle an empty result to destroy. This
# file pins what the caller sees: the exception, with the engine's reason in
# it; a batch that left nothing behind; a connection that carries on.
#
# A crash is not a test result. Every scenario runs in a process of its own,
# which writes down what it saw as it goes, and the assertions are made here,
# on that report and on how the process ended. So this file runs to its end
# and says which scenario died of which signal, where a scenario run in this
# process would take the file and every result before it along.
#
# Offline, and always in-memory: every scenario needs an empty database of
# its own, so DBIO_TEST_DUCKDB_DSN is deliberately not consulted here.

use strict;
use warnings;
use Test::More;
use File::Temp ();
use DBIO::Util qw(file_path slurp_file_utf8);

# ---- the process a scenario runs in -------------------------------------
# perl -e <this> <scenario> <report file>. The report is rewritten after every
# step, so a process that dies leaves everything it saw up to there.
my $SCENARIO = <<'EOS';
use strict;
use warnings;
use DBI;
use POSIX ();
use DBIO::Util ();
use DBIO::DuckDB::Test;

my ($scenario, $report_file) = @ARGV;

my @report;
sub report {
  my ($key, $value) = @_;
  $value =~ s/\s+/ /g;
  push @report, "$key\t$value\n";
  DBIO::Util::write_file($report_file, join '', @report);
  return;
}

# What a piece of code answered, or how it died.
sub outcome (&) {
  my ($code) = @_;
  my @got;
  return 'died: ' . ($@ || 'no message') unless eval { @got = $code->(); 1 };
  return join ' ', 'returned', map { $_ // 'undef' } @got;
}

# One artist, so that key 1 is taken.
sub schema {
  my $schema = DBIO::DuckDB::Test->init_schema(
    dsn         => 'dbi:DuckDB:dbname=:memory:',
    no_populate => 1,
    @_,
  );
  $schema->storage->dbh_do(sub {
    $_[1]->do(q{INSERT INTO artist (artistid, name, rank) VALUES (1, 'taken', 1)});
  });
  return $schema;
}

# 'artistid:name ...' as the table holds it, in key order.
sub stored {
  my ($schema) = @_;
  my $rows = $schema->storage->dbh_do(sub {
    $_[1]->selectall_arrayref('SELECT artistid, name FROM artist ORDER BY artistid');
  });
  return join ' ', map { "$_->[0]:$_->[1]" } @$rows;
}

my $REFUSED = q{INSERT INTO artist (artistid, name) VALUES (?, ?)};

my %populate = (
  'populate, first row refused'  => [ [qw(artistid name)], [ 1, 'dup' ], [ 2, 'new' ] ],
  'populate, later row refused'  => [ [qw(artistid name)], [ 2, 'new' ], [ 1, 'dup' ] ],
  'populate of literals refused' => [ [qw(artistid name)], [ \'1', \q{'dup'} ] ],
);

if (my $rows = $populate{$scenario}) {
  my $schema = schema();
  my $rs     = $schema->resultset('Artist');

  # populate is not the last statement of the block: void context, which is
  # what sends it down the bulk path.
  report refused => outcome { $rs->populate($rows); 'no exception' };
  report depth   => $schema->storage->transaction_depth;
  report stored  => stored($schema);

  report again        => outcome { $rs->populate([ [qw(artistid name)], [ 2, 'second' ], [ 3, 'third' ] ]); 'populated' };
  report stored_after => stored($schema);

  $schema->storage->disconnect;
}
elsif ($scenario eq 'finish by hand') {
  my $schema = schema();

  $schema->storage->dbh_do(sub {
    my ($storage, $dbh) = @_;

    my $refused = $dbh->prepare($REFUSED);
    report execute_refused      => outcome { $refused->execute(1, 'dup'); 'no exception' };
    report finish_after_refused => outcome { $refused->finish };

    my $read = $dbh->prepare('SELECT name FROM artist WHERE artistid = 1');
    $read->execute;
    report read         => outcome { $read->fetchrow_array };
    report finish       => outcome { $read->finish };
    report finish_again => outcome { $read->finish };

    my $never_executed = $dbh->prepare('SELECT 1');
    report finish_never_executed => outcome { $never_executed->finish };

    return;
  });

  report stored => stored($schema);
  $schema->storage->disconnect;
}
elsif ($scenario eq 'finish with an application callback') {
  my $seen   = 0;
  my $schema = schema(
    connect_opts => {
      RaiseError => 1, PrintError => 0,
      Callbacks  => { ChildCallbacks => { finish => sub { $seen++; return } } },
    },
  );

  $schema->storage->dbh_do(sub {
    my $refused = $_[1]->prepare($REFUSED);
    report execute_refused      => outcome { $refused->execute(1, 'dup'); 'no exception' };
    report finish_after_refused => outcome { $refused->finish };
    return;
  });

  report callback_fired => $seen;
  $schema->storage->disconnect;
}
elsif ($scenario eq 'finish in a forked child') {
  my $schema = schema();

  $schema->storage->dbh_do(sub {
    my $refused = $_[1]->prepare($REFUSED);
    report execute_refused => outcome { $refused->execute(1, 'dup'); 'no exception' };

    defined(my $pid = fork) or die "fork failed: $!";
    if (!$pid) {
      # Nothing but the finish: no destructors, no END blocks in the copy.
      my $ok = eval { $refused->finish; 1 };
      POSIX::_exit($ok ? 0 : 7);
    }
    waitpid $pid, 0;
    report forked_child => ($? & 127) ? 'killed by signal ' . ($? & 127) : 'exit ' . ($? >> 8);
    return;
  });

  $schema->storage->disconnect;
}
elsif ($scenario eq 'plain DBD::DuckDB') {
  my $dbh = DBI->connect('dbi:DuckDB:dbname=:memory:', '', '',
    { RaiseError => 1, PrintError => 0 });
  $dbh->do('CREATE TABLE t (i INTEGER PRIMARY KEY)');
  $dbh->do('INSERT INTO t VALUES (1)');

  my $refused = $dbh->prepare('INSERT INTO t VALUES (?)');
  report execute_refused      => outcome { $refused->execute(1); 'no exception' };
  report finish_after_refused => outcome { $refused->finish };

  $dbh->disconnect;
}
else {
  die "unknown scenario '$scenario'\n";
}
EOS

my $tmp = File::Temp->newdir;
my $n   = 0;

# Runs one scenario and answers with its report, plus 'ended': how the
# process went. The scenario's @INC is this one's, so it loads the same
# modules whether the suite runs under prove -l or against a build.
sub scenario {
  my ($name) = @_;

  my $report = file_path($tmp, 'k38-' . ++$n . '.report');
  my $rc     = system($^X, (map { "-I$_" } grep { !ref } @INC), '-e', $SCENARIO, $name, $report);
  die "could not run the scenario process: $!" if $rc == -1;

  my %got = (
    ended => ($rc & 127) ? 'killed by signal ' . ($rc & 127) : 'exit ' . ($rc >> 8),
  );
  if (-e $report) {
    for my $line (split /\n/, slurp_file_utf8($report)) {
      my ($key, $value) = split /\t/, $line, 2;
      $got{$key} = $value;
    }
  }
  return \%got;
}

# A step the process never reported is a failure of that step, in words.
sub seen {
  my ($got, $key) = @_;
  return $got->{$key} // 'nothing: the process did not get that far';
}

# DuckDB has two wordings for a key that is taken -- 'Duplicate key
# "artistid: 1" violates primary key constraint' where the row holding it is
# committed, as here, and 'PRIMARY KEY or UNIQUE constraint violation:
# duplicate key "1"' where it came in the same transaction. Both name the
# error class and the cause, and that is what is asked for.
my $DUPLICATE_KEY = qr/\Adied: .*Constraint Error.*duplicate key/i;

# ---- populate: the first row is refused --------------------------------
# The crash. With binds it goes through execute_for_fetch, without any --
# every value a literal -- through a plain execute per row; core finishes the
# handle after either.
for my $name ('populate, first row refused', 'populate of literals refused') {
  my $got = scenario($name);

  like seen($got, 'refused'), $DUPLICATE_KEY,
    "$name: an exception that carries the engine's reason";
  is seen($got, 'depth'), 0, "$name: no transaction is left open";
  is seen($got, 'stored'), '1:taken', "$name: nothing of the batch is stored";

  is seen($got, 'again'), 'returned populated',
    "$name: the next populate on the same connection goes through";
  is seen($got, 'stored_after'), '1:taken 2:second 3:third',
    "$name: and its rows are stored";

  is $got->{ended}, 'exit 0', "$name: the process ends normally";
}

# ---- populate: a later row is refused ----------------------------------
# Never a crash -- the first row succeeded, so the handle has a result to
# destroy. It is here for what the rollback has to undo: a row that did go
# in before the batch failed.
{
  my $name = 'populate, later row refused';
  my $got  = scenario($name);

  like seen($got, 'refused'), $DUPLICATE_KEY,
    "$name: an exception that carries the engine's reason";
  is seen($got, 'depth'), 0, "$name: no transaction is left open";
  is seen($got, 'stored'), '1:taken',
    "$name: the row that went in before it is rolled back";

  is seen($got, 'again'), 'returned populated',
    "$name: the next populate on the same connection goes through";
  is seen($got, 'stored_after'), '1:taken 2:second 3:third',
    "$name: and its rows are stored";

  is $got->{ended}, 'exit 0', "$name: the process ends normally";
}

# ---- finish by hand ----------------------------------------------------
# The three ways a handle comes to finish without a result, on handles the
# caller prepared through dbh_do. finish answers as DBD::DuckDB has it answer
# everywhere else.
{
  my $name = 'finish by hand';
  my $got  = scenario($name);

  like seen($got, 'execute_refused'), $DUPLICATE_KEY,
    "$name: premise -- the execute was refused by the engine";
  is seen($got, 'finish_after_refused'), 'returned 1',
    "$name: finish after the refused execute";

  is seen($got, 'read'),         'returned taken', "$name: premise -- a handle that was executed and read";
  is seen($got, 'finish'),       'returned 1',     "$name: its finish";
  is seen($got, 'finish_again'), 'returned 1',     "$name: and a second finish";

  is seen($got, 'finish_never_executed'), 'returned 1',
    "$name: finish on a handle that was never executed";

  is seen($got, 'stored'), '1:taken', "$name: the connection carries on";
  is $got->{ended}, 'exit 0', "$name: the process ends normally";
}

# ---- callbacks the application installed keep working ------------------
# The empty result is handed over in a DBI callback on finish, the place an
# application may have a callback of its own.
{
  my $name = 'finish with an application callback';
  my $got  = scenario($name);

  like seen($got, 'execute_refused'), $DUPLICATE_KEY,
    "$name: premise -- the execute was refused by the engine";
  is seen($got, 'finish_after_refused'), 'returned 1', "$name: finish after the refused execute";
  is seen($got, 'callback_fired'), 1, "$name: the application's own callback fired, once";
  is $got->{ended}, 'exit 0', "$name: the process ends normally";
}

# ---- a handle carried across a fork ------------------------------------
# The statement release next to it stands down in a forked child, because
# only the process that opened the database frees anything in it. An empty
# result frees nothing, and a child that finishes the handle it inherited
# must not crash either.
{
  my $name = 'finish in a forked child';
  my $got  = scenario($name);

  like seen($got, 'execute_refused'), $DUPLICATE_KEY,
    "$name: premise -- the execute was refused by the engine";
  is seen($got, 'forked_child'), 'exit 0', "$name: the child finishes the handle and ends normally";
  is $got->{ended}, 'exit 0', "$name: and so does the process that forked it";
}

# ---- upstream sentinel -------------------------------------------------
# A plain DBI handle, no DBIO: the crash itself. When this starts to pass,
# DBD::DuckDB has been fixed and the empty result in DBIO::DuckDB::Storage
# can go (see docs/upstream/). That it still crashes in a process that has
# DBIO::DuckDB::Storage loaded is the other half: the storage changes its own
# connection's handles and nothing in DBD::DuckDB.
{
  my $name = 'plain DBD::DuckDB';
  my $got  = scenario($name);

  like seen($got, 'execute_refused'), qr/\Adied: .*Constraint Error/,
    "$name: premise -- the execute was refused by the engine";

  TODO: {
    local $TODO = 'DBD::DuckDB 0.16 finish crashes on a handle without a result (karr k38)';
    is $got->{ended}, 'exit 0', "$name: finish after a refused execute does not end the process";
  }
}

done_testing;
