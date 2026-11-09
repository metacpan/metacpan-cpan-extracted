use strict;
use warnings;
use Test::More;

# LIVE (karr k48, k49): what DBD::Firebird does with the statements of a
# connection, on a raw DBI handle and nothing else of this distribution.
#
# This file pins the DBD's behaviour that ADR 0011, Storage::InterBase::_prepare_sth
# and Storage::InterBase::_ping are written around. It is not a claim about our
# code: each test says what the DBD does today, and the one that goes red when a
# DBD release stops doing it is the signal that a workaround can be looked at
# again (the upstream drafts are in maint/upstream/).
#
#   1. a statement destroyed by the commit after DDL executes without an error
#      and an INSERT through it writes nothing (ADR 0011);
#   2. a destroyed handle that Perl frees later empties the DBD's list of
#      statements: one prepared since is alive, off the list, and keeps its
#      table "in use" for a DROP TABLE -- while with the destroyed handle
#      still held, the same DROP works (karr k48); a control case shows the
#      freeing is what does it;
#   3. a DDL commit the server refuses is not rolled back: every later
#      statement fails with the same error, a plain rollback under AutoCommit
#      does nothing, begin_work + rollback clears it (karr k49);
#
# Skipped unless DBIO_TEST_FIREBIRD_DSN / _USER / _PASS are set.
#
# WARNING: creates and drops the tables "k48_t" and "k48_o".

my $dsn  = $ENV{DBIO_TEST_FIREBIRD_DSN};
my $user = $ENV{DBIO_TEST_FIREBIRD_USER};
my $pass = $ENV{DBIO_TEST_FIREBIRD_PASS};

plan skip_all => 'Set DBIO_TEST_FIREBIRD_DSN, _USER, _PASS to run the live DBD tests'
  unless $dsn;

eval { require DBI; require DBD::Firebird; 1 }
  or plan skip_all => 'DBI / DBD::Firebird not installed';

note "DBD::Firebird $DBD::Firebird::VERSION";

my $connect = sub {
  DBI->connect($dsn, $user, $pass, {
    RaiseError => 1, PrintError => 0, AutoCommit => 1, ib_dialect => 3,
  }) or die DBI->errstr;
};
my $check = $connect->();
my $count = sub {
  my ($t) = @_;
  return ($check->selectrow_array(
    q{select count(*) from } . $t))[0];
};
my $clean = sub { eval { $check->do("DROP TABLE $_") } for qw( k48_t k48_o ) };
my $fresh = sub {
  my $dbh = $connect->();
  $clean->();
  $dbh->do('CREATE TABLE k48_t (id INTEGER)');
  return $dbh;
};
my @warnings;
local $SIG{__WARN__} = sub { push @warnings, $_[0] };

# --- 1. a destroyed statement is silent -------------------------------------
{
  my $dbh = $fresh->();
  my $ins = $dbh->prepare('INSERT INTO k48_t VALUES (?)');
  $ins->execute(1);
  $dbh->do('CREATE TABLE k48_o (id INTEGER)');          # DDL commit

  my $r = eval { $ins->execute(2) };
  is($@, '', '1. a statement destroyed by the DDL commit executes without an error');
  ok(!$r || $r eq '0E0', '... answering false or 0E0, not a row count')
    or diag "answered '$r'";
  is($count->('k48_t'), 1, '... and writes nothing');
  ok(!$ins->bind_param($ins->{NUM_OF_PARAMS} + 1, undef),
    '... and is what the storage\'s _sth_is_alive question answers false for');
  undef $ins;
  $dbh->disconnect;
}

# --- 2. a destroyed handle freed later empties the list ----------------------
for my $case ([ 'freed' => 1 ], [ 'held' => 0 ]) {
  my ($name, $free) = @$case;
  my $dbh = $fresh->();
  my $first = $dbh->prepare('SELECT id FROM k48_t');
  $dbh->do('CREATE TABLE k48_o (id INTEGER)');           # destroys $first
  my $held = $dbh->prepare('SELECT id FROM k48_t');
  $held->execute;
  undef $first if $free;
  $dbh->do('ALTER TABLE k48_o ADD x INTEGER');           # DDL commit

  my $dropped = eval { $dbh->do('DROP TABLE k48_t'); 1 };
  if ($free) {
    ok(!$dropped && $@ =~ /is in use/,
      '2. the destroyed handle freed after another was prepared: DROP TABLE of the '
    . 'table that one holds is refused, "in use"') or diag $@;
  }
  else {
    ok($dropped, '... with the destroyed handle still held, the same DROP goes through')
      or diag $@;
  }

  if ($free) {
    # --- 3. the refused commit is not rolled back ------------------------------
    my $again = eval { $dbh->do('select 1 from rdb$database'); 1 };
    ok(!$again && $@ =~ /is in use/,
      '3. the next statement fails with the same error: the commit was not rolled back');

    { local $SIG{__WARN__} = sub {};
      eval { $dbh->rollback };
    }
    $again = eval { $dbh->do('select 1 from rdb$database'); 1 };
    ok(!$again, '... a plain rollback under AutoCommit does not clear it');

    ok(eval { $dbh->begin_work; $dbh->rollback; 1 }, '... begin_work + rollback does')
      or diag $@;
    ok(eval { $dbh->do('select 1 from rdb$database'); 1 }, '... the handle answers again')
      or diag $@;
    ok($dbh->{AutoCommit}, '... with AutoCommit on');
    is($count->('rdb$relations where rdb$relation_name = \'K48_T\''), 1,
      '... the refused DROP was not applied');
  }
  undef $held;
  $dbh->disconnect;
}

$clean->();
$check->disconnect;
is_deeply([ grep { !/no statement executing/ } @warnings ], [], 'no other warnings')
  or diag @warnings;
done_testing;
