use strict;
use warnings;
use Test::More;
use DBIO::Optional::Dependencies ();

# LIVE (karr k27): a foreign key that stays over a unique constraint the diff
# drops. The server takes the key along with the constraint, and a later
# DROP CONSTRAINT of the key is -623 (asserted below, not assumed). So the diff
# drops the key first and adds it again last.
#
# The target model keeps the key but not the constraint. Nothing else covers
# the key's columns in it (a changed primary key is not diffed), so the final
# ADD of the key is answered with -297: that is the server saying the target
# model is not a valid schema, and it is asserted as such. What the test is
# about is everything before it: the key drops, the constraint drops, no -623.
# Creates and drops only the tables "zz_ix_k27_*".

plan skip_all => 'Test needs ' . DBIO::Optional::Dependencies->req_missing_for('test_rdbms_informix')
  unless DBIO::Optional::Dependencies->req_ok_for('test_rdbms_informix');
my ($dsn, $user, $pass) = @ENV{map { "DBIO_TEST_INFORMIX_$_" } qw/DSN USER PASS/};
plan skip_all => 'Set $ENV{DBIO_TEST_INFORMIX_DSN}, _USER and _PASS to run this test' unless $dsn;

use DBI;
use DBIO::Informix::Introspect;
use DBIO::Informix::Diff;

my $dbh = DBI->connect($dsn, $user, $pass, { RaiseError => 0, PrintError => 0, AutoCommit => 1 })
  or die $DBI::errstr;
my @tables = qw(zz_ix_k27_c zz_ix_k27_p);
sub cleanup { $dbh->do("DROP TABLE $_") for @tables }
cleanup();
END { cleanup() if $dbh }
sub run { my ($sql) = @_; my $r = $dbh->do($sql); return defined $r ? '' : "$DBI::err" }

sub build {
  is run('CREATE TABLE zz_ix_k27_p (id INTEGER NOT NULL, code INTEGER NOT NULL, PRIMARY KEY (id))'), '', 'parent';
  is run('ALTER TABLE zz_ix_k27_p ADD CONSTRAINT UNIQUE (code) CONSTRAINT zz_ix_k27_p_code'), '', '... its unique constraint';
  is run('CREATE TABLE zz_ix_k27_c (id INTEGER NOT NULL, pcode INTEGER, PRIMARY KEY (id))'), '', 'child';
  is run('ALTER TABLE zz_ix_k27_c ADD CONSTRAINT FOREIGN KEY (pcode) REFERENCES zz_ix_k27_p(code) CONSTRAINT zz_ix_k27_c_fk'), '',
    '... its key onto the constraint';
}

sub only_ours {
  my ($model) = @_;
  my %m = %$model;
  for my $k (qw(tables columns indexes foreign_keys unique_constraints)) {
    $m{$k} = { map { $_ => $model->{$k}{$_} } grep { /\Azz_ix_k27_/ } keys %{ $model->{$k} // {} } };
  }
  return \%m;
}
sub model { only_ours(DBIO::Informix::Introspect->new(dbh => $dbh)->model) }

# --- the server's own rule, measured ---------------------------------------------
build();
is run('ALTER TABLE zz_ix_k27_p DROP CONSTRAINT zz_ix_k27_p_code'), '', 'the unique constraint is dropped under its key';
is run('ALTER TABLE zz_ix_k27_c DROP CONSTRAINT zz_ix_k27_c_fk'), -623,
  '... and the key went with it: a later DROP CONSTRAINT of the key is -623';
cleanup();

# --- the diff -----------------------------------------------------------------------
build();
my $source = model();
my $target = model();
$target->{unique_constraints}{zz_ix_k27_p} = [];
my @sql = split /\n/, DBIO::Informix::Diff->new(source => $source, target => $target)->as_sql;
@sql = grep { /^ALTER/ } @sql;
is scalar @sql, 3, 'the diff has three statements' or diag join "\n", @sql;
like $sql[0], qr/^ALTER TABLE zz_ix_k27_c DROP CONSTRAINT /, 'the key goes first';
like $sql[1], qr/^ALTER TABLE zz_ix_k27_p DROP CONSTRAINT /, 'the constraint second';
like $sql[2], qr/^ALTER TABLE zz_ix_k27_c ADD CONSTRAINT FOREIGN KEY \(pcode\) REFERENCES zz_ix_k27_p\(code\)/, 'the key comes back last';
is run($sql[0]), '', 'the server takes the key drop';
is run($sql[1]), '', '... the constraint drop (no -623 anywhere)';
is run($sql[2]), -297, '... and refuses the key without anything unique under it (-297): the target model is not a schema';
is scalar @{ model()->{unique_constraints}{zz_ix_k27_p} // [] }, 0, 'the constraint is gone';

done_testing;
