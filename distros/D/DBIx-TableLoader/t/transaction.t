# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
use strict;
use warnings;
use Test::More 0.96;
use Try::Tiny;
use Test::Fatal;
use lib 't/lib';
use TLDBH;

my $mod = 'DBIx::TableLoader';
eval "require $mod" or die $@;

sub test_transaction {
  my @args = (
    data => [
      [qw(a b c)],
      [qw(1 2 3)],
    ],
    handle_invalid_row => 'die',
    @_,
  );

  my $loadex = sub {
    my $table = shift;
    exception { new_ok($mod, [name => $table, @args])->load(); }
  };

  # success
  is $loadex->('tbl1'), undef, 'no exceptions!';

  # add an extra field to throw an error
  push @{ $args[1]->[1] }, 4;

  # failure
  like $loadex->('tbl2'),
    qr/Row has 4 fields when 3 are expected/,
    'only the good die young';
}

subtest mocked => sub {
  my $dbh = TLDBH->new;

  test_transaction(dbh => $dbh);

  is $dbh->{begin},    2, 'two begins';
  is $dbh->{commit},   1, 'one commit';
  is $dbh->{rollback}, 1, 'one rollback';
  is $dbh->{tr},       0, 'transactions reset';
};

subtest sqlite => sub {
  eval 'require DBD::SQLite'
    or plan skip_all => 'DBD::SQLite required for these tests';

  require DBI;
  my $dbh = DBI->connect('dbi:SQLite:dbname=:memory:', undef, undef, {
    RaiseError => 1,
    PrintError => 0,
  });

  # roar!
  my $trex = sub {
    # try to open a transaction
    exception { $dbh->begin_work; $dbh->rollback; }
  };

  try {
    # open transaction
    $dbh->begin_work;
    # try to do it again
    like $trex->(),
      qr/DBD::SQLite::db begin_work failed: Already in a transaction/,
      'open transaction error';
    # reset
    $dbh->rollback;
  } catch {
    # shouldn't reach here, but show it if we do
    diag $_[0];
  };

  test_transaction(dbh => $dbh);

  is $trex->(), undef, 'no errors, transaction not open';
};

done_testing;
