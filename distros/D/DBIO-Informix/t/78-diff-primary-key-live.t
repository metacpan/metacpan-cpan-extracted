use strict;
use warnings;
use Test::More;
use DBIO::Optional::Dependencies ();

# LIVE (karr k28): a changed primary key reaches the database. Measured on
# Informix 15.0.1 and asserted below, not assumed:
#  * there is no DROP PRIMARY KEY (-201) and a second key is refused (-704),
#    so the old key goes first, by the name the introspection reads
#    (primary_key_name), the new one is added without a name;
#  * dropping the primary key takes the foreign keys over it along, a later
#    DROP CONSTRAINT of such a key is -623: the diff drops the key first and
#    adds it back after the constraint that now stands under it.
# Creates and drops only the tables "zz_ix_k28_*".

plan skip_all => 'Test needs ' . DBIO::Optional::Dependencies->req_missing_for('test_rdbms_informix')
  unless DBIO::Optional::Dependencies->req_ok_for('test_rdbms_informix');
my ($dsn, $user, $pass) = @ENV{map { "DBIO_TEST_INFORMIX_$_" } qw/DSN USER PASS/};
plan skip_all => 'Set $ENV{DBIO_TEST_INFORMIX_DSN}, _USER and _PASS to run this test' unless $dsn;

use DBI;
use DBIO::Informix::Introspect;
use DBIO::Informix::Diff;

my $dbh = DBI->connect($dsn, $user, $pass, { RaiseError => 0, PrintError => 0, AutoCommit => 1 })
  or die $DBI::errstr;
my @tables = qw(zz_ix_k28_c zz_ix_k28_p);
sub cleanup { $dbh->do("DROP TABLE $_") for @tables }
cleanup();
END { cleanup() if $dbh }
sub run { my ($sql) = @_; my $r = $dbh->do($sql); return defined $r ? '' : "$DBI::err" }

sub only_ours {
  my ($model) = @_;
  my %m = %$model;
  for my $k (qw(tables columns indexes foreign_keys unique_constraints)) {
    $m{$k} = { map { $_ => $model->{$k}{$_} } grep { /\Azz_ix_k28_/ } keys %{ $model->{$k} // {} } };
  }
  return \%m;
}
sub model { only_ours(DBIO::Informix::Introspect->new(dbh => $dbh)->model) }
sub set_pk {
  my ($model, $table, @cols) = @_;
  my $pos = 0;
  my %at = map { $_ => ++$pos } @cols;
  for my $c (@{ $model->{columns}{$table} }) {
    ($c->{is_pk}, $c->{pk_position}) = $at{ $c->{column_name} } ? (1, $at{ $c->{column_name} }) : (0, 0);
  }
  delete $model->{tables}{$table}{primary_key_name};
}
sub alters { [ grep { /^ALTER/ } split /\n/, $_[0] ] }

# --- the server's own rules, measured ---------------------------------------------------
is run('CREATE TABLE zz_ix_k28_p (a INTEGER NOT NULL, b INTEGER NOT NULL, code INTEGER NOT NULL, PRIMARY KEY (a))'), '', 'parent';
is run('ALTER TABLE zz_ix_k28_p DROP PRIMARY KEY'), -201, 'there is no DROP PRIMARY KEY (-201)';
is run('ALTER TABLE zz_ix_k28_p ADD CONSTRAINT PRIMARY KEY (b)'), -704, '... and a second primary key is refused (-704)';
cleanup();

# --- a changed key ------------------------------------------------------------------------
is run('CREATE TABLE zz_ix_k28_p (a INTEGER NOT NULL, b INTEGER NOT NULL, code INTEGER NOT NULL, PRIMARY KEY (a))'), '', 'parent';
is run('ALTER TABLE zz_ix_k28_p ADD CONSTRAINT UNIQUE (code) CONSTRAINT zz_ix_k28_p_code'), '', '... its unique constraint';
is run('CREATE TABLE zz_ix_k28_c (id INTEGER NOT NULL, pcode INTEGER, PRIMARY KEY (id))'), '', 'child';
is run('ALTER TABLE zz_ix_k28_c ADD CONSTRAINT FOREIGN KEY (pcode) REFERENCES zz_ix_k28_p(code) CONSTRAINT zz_ix_k28_c_fk'), '',
  '... its key onto the unique constraint';

my $source = model();
like $source->{tables}{zz_ix_k28_p}{primary_key_name}, qr/\S/, 'the introspection reads the name of the primary key';
my $target = model();
set_pk($target, 'zz_ix_k28_p', 'b', 'a');
my $sql = DBIO::Informix::Diff->new(source => $source, target => $target)->as_sql;
my $stmts = alters($sql);
is scalar @$stmts, 2, 'the diff has two statements (the key over the unique constraint is not touched)' or diag $sql;
like $stmts->[0], qr/^ALTER TABLE zz_ix_k28_p DROP CONSTRAINT \S+;$/, 'the old key is dropped by its name';
like $stmts->[1], qr/^ALTER TABLE zz_ix_k28_p ADD CONSTRAINT PRIMARY KEY \(b, a\);$/, '... the new one added, columns in key order';
is run($_), '', "server takes: $_" for @$stmts;
my $after = model();
is_deeply [ map { $_->{column_name} } sort { $a->{pk_position} <=> $b->{pk_position} } grep { $_->{is_pk} } @{ $after->{columns}{zz_ix_k28_p} } ],
  [ 'b', 'a' ], 'the database holds the key (b, a)';
ok !DBIO::Informix::Diff->new(source => $after, target => $target)->has_changes, 'and the diff afterwards is empty';
cleanup();

# --- a foreign key over the dropped key ---------------------------------------------------
is run('CREATE TABLE zz_ix_k28_p (a INTEGER NOT NULL, b INTEGER NOT NULL, PRIMARY KEY (a))'), '', 'parent';
is run('CREATE TABLE zz_ix_k28_c (id INTEGER NOT NULL, pa INTEGER, PRIMARY KEY (id))'), '', 'child';
is run('ALTER TABLE zz_ix_k28_c ADD CONSTRAINT FOREIGN KEY (pa) REFERENCES zz_ix_k28_p(a) CONSTRAINT zz_ix_k28_c_fk'), '',
  '... its key onto the primary key';
is run('ALTER TABLE zz_ix_k28_p DROP CONSTRAINT ' . model()->{tables}{zz_ix_k28_p}{primary_key_name}), '',
  'the primary key is dropped under its key';
is run('ALTER TABLE zz_ix_k28_c DROP CONSTRAINT zz_ix_k28_c_fk'), -623, '... and the key went with it: a later DROP CONSTRAINT of the key is -623';
cleanup();

is run('CREATE TABLE zz_ix_k28_p (a INTEGER NOT NULL, b INTEGER NOT NULL, PRIMARY KEY (a))'), '', 'parent';
is run('CREATE TABLE zz_ix_k28_c (id INTEGER NOT NULL, pa INTEGER, PRIMARY KEY (id))'), '', 'child';
is run('ALTER TABLE zz_ix_k28_c ADD CONSTRAINT FOREIGN KEY (pa) REFERENCES zz_ix_k28_p(a) CONSTRAINT zz_ix_k28_c_fk'), '', '... its key';
$source = model();
$target = model();
set_pk($target, 'zz_ix_k28_p');                                    # no primary key ...
$target->{unique_constraints}{zz_ix_k28_p} = [ { constraint_name => undef, columns => ['a'] } ];   # ... a unique constraint instead
$stmts = alters(DBIO::Informix::Diff->new(source => $source, target => $target)->as_sql);
is scalar @$stmts, 4, 'the diff has four statements' or diag join "\n", @$stmts;
like $stmts->[0], qr/^ALTER TABLE zz_ix_k28_c DROP CONSTRAINT zz_ix_k28_c_fk;$/, 'the key over the primary key goes first';
like $stmts->[1], qr/^ALTER TABLE zz_ix_k28_p DROP CONSTRAINT \S+;$/, 'the primary key second';
like $stmts->[2], qr/^ALTER TABLE zz_ix_k28_p ADD CONSTRAINT UNIQUE \(a\);$/, 'the unique constraint stands under the key ...';
like $stmts->[3], qr/^ALTER TABLE zz_ix_k28_c ADD CONSTRAINT FOREIGN KEY \(pa\) REFERENCES zz_ix_k28_p\(a\)/, '... and the key comes back last';
is run($_), '', "server takes: $_" for @$stmts;
ok !DBIO::Informix::Diff->new(source => model(), target => $target)->has_changes, 'the diff afterwards is empty';

done_testing;
