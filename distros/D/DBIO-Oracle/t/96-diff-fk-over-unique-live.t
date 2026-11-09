use strict;
use warnings;

use Test::More;
use Test::Exception;
use DBI;
use Storable ();
use DBIO::Optional::Dependencies ();
use DBIO::Oracle::Introspect;
use DBIO::Oracle::Diff;

# LIVE (karr k64, hub decision). A foreign key that stays, over a unique
# constraint the target changes or removes.
#
# Oracle refuses to drop a unique constraint a foreign key rests on
# (ORA-02273), whatever else the target says about the key. What this file
# claims, against the server:
#
#   1. The premise: DROP CONSTRAINT on that unique constraint alone is
#      ORA-02273.
#   2. A target that changes the constraint (same columns in another order,
#      so the diff sees a change) and keeps the key: the diff drops the key,
#      drops the constraint, adds it, adds the key again, unchanged. The
#      statements run; the server then holds the key and the new constraint
#      and pairs the columns as before.
#   3. A target that removes the constraint and keeps a key on its columns:
#      the diff refuses, naming table and columns, before a statement is
#      written; the database is as it was.

my ($dsn, $user, $pass) = @ENV{map { "DBIO_TEST_ORA_${_}" } qw/DSN USER PASS/};

plan skip_all => 'Set $ENV{DBIO_TEST_ORA_DSN}, _USER and _PASS to run this test'
  unless $dsn && defined $user && defined $pass;

plan skip_all => 'Test needs '
  . DBIO::Optional::Dependencies->req_missing_for('test_rdbms_oracle')
  unless DBIO::Optional::Dependencies->req_ok_for('test_rdbms_oracle');

alarm 300;

my $dbh = DBI->connect($dsn, $user, $pass, {
  RaiseError => 1, PrintError => 0, AutoCommit => 1,
});

sub wipe {
  for my $t (qw(T96_CHILD T96_PARENT)) {
    eval { $dbh->do("DROP TABLE $t CASCADE CONSTRAINTS PURGE"); 1 }
      or $@ =~ /ORA-00942\b/
      or die $@;
  }
}

wipe();

$dbh->do($_) for (
  'CREATE TABLE T96_PARENT (ID NUMBER(10) NOT NULL, A VARCHAR2(10), B VARCHAR2(10),'
. ' CONSTRAINT T96_PARENT_PK PRIMARY KEY (ID), CONSTRAINT T96_PARENT_UQ UNIQUE (A, B))',
  'CREATE TABLE T96_CHILD (ID NUMBER(10) NOT NULL, X VARCHAR2(10), Y VARCHAR2(10),'
. ' CONSTRAINT T96_CHILD_PK PRIMARY KEY (ID),'
. ' CONSTRAINT T96_CHILD_FK FOREIGN KEY (X, Y) REFERENCES T96_PARENT (A, B))',
);

sub model {
  my $m = DBIO::Oracle::Introspect->new(dbh => $dbh)->model;
  my %mine = map { $_ => 1 } qw(T96_CHILD T96_PARENT);
  for my $section (qw(tables columns indexes foreign_keys primary_keys unique_constraints)) {
    $m->{$section} = { map { $_ => $m->{$section}{$_} } grep { $mine{$_} } keys %{ $m->{$section} // {} } };
  }
  $m->{views} = {};
  return $m;
}

sub ops { DBIO::Oracle::Diff->new(source => $_[0], target => $_[1])->operations }
sub sql { [ map { $_->as_sql } @{ ops(@_) } ] }

sub unique_columns {
  return $dbh->selectcol_arrayref(q{
    SELECT cc.column_name FROM user_constraints c
    JOIN user_cons_columns cc ON cc.constraint_name = c.constraint_name
    WHERE c.constraint_name = 'T96_PARENT_UQ' ORDER BY cc.position
  });
}

my $source = model();
is_deeply $source->{unique_constraints}{T96_PARENT}, [ [ T96_PARENT_UQ => [qw(A B)] ] ],
  'the introspected model has the unique constraint';
is scalar @{ $source->{foreign_keys}{T96_CHILD} }, 1, '... and the key over it';

# 1. the premise
throws_ok { $dbh->do('ALTER TABLE T96_PARENT DROP CONSTRAINT T96_PARENT_UQ') }
  qr/ORA-02273/, 'Oracle refuses to drop the constraint under the key (ORA-02273)';

# 2. changed constraint, key stays
{
  my $target = Storable::dclone($source);
  $target->{unique_constraints}{T96_PARENT} = [ [ T96_PARENT_UQ => [qw(B A)] ] ];

  my $sql = sql($source, $target);
  is_deeply $sql, [
    'ALTER TABLE "T96_CHILD" DROP CONSTRAINT "T96_CHILD_FK";',
    'ALTER TABLE "T96_PARENT" DROP CONSTRAINT "T96_PARENT_UQ";',
    'ALTER TABLE "T96_PARENT" ADD CONSTRAINT "T96_PARENT_UQ" UNIQUE ("B", "A");',
    'ALTER TABLE "T96_CHILD" ADD CONSTRAINT "T96_CHILD_FK" FOREIGN KEY ("X", "Y")'
  . ' REFERENCES "T96_PARENT" ("A", "B");',
  ], 'the key goes, the constraint is replaced, the key comes back unchanged';

  for my $stmt (@$sql) {
    (my $run = $stmt) =~ s/;\z//;
    lives_ok { $dbh->do($run) } "runs: $run";
  }

  is_deeply unique_columns(), [qw(B A)], 'the server holds the new constraint';
  # Oracle lists the pairs of a key in the order of the constraint it is bound
  # to, so the key reads back as (Y, X) -> (B, A): the same pairs, X to A and
  # Y to B, in another order. That is the server's, not the diff's.
  my $pairs = $dbh->selectcol_arrayref(q{
    SELECT cc.column_name || '>' || rc.column_name
    FROM user_constraints c
    JOIN user_cons_columns cc ON cc.constraint_name = c.constraint_name
    JOIN user_cons_columns rc ON rc.constraint_name = c.r_constraint_name
                             AND rc.position = cc.position
    WHERE c.constraint_name = 'T96_CHILD_FK' ORDER BY cc.column_name
  });
  is_deeply $pairs, [qw(X>A Y>B)], 'and the key is back, X to A and Y to B';
}

# 3. removed constraint, key stays: refused before a statement
{
  my $now    = model();
  my $target = Storable::dclone($now);
  $target->{unique_constraints}{T96_PARENT} = [];

  throws_ok { ops($now, $target) }
    qr/foreign key 'T96_CHILD_FK' of table 'T96_CHILD' \(columns Y, X\).*columns B, A of table 'T96_PARENT'/s,
    'a constraint removed under a key that stays is refused, naming table and columns';
  is_deeply unique_columns(), [qw(B A)], 'and the database is as it was';
}

END { wipe() if $dbh }

done_testing;
