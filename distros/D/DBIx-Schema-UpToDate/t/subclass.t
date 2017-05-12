# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
use strict;
use warnings;
use Test::More 0.96;

use lib 't/lib';
use Test_Schema ();
use DBI ();

sub test_with_dbd {
  my ($dbd, $sub) = @_;
  subtest $dbd => sub {
    eval "require DBD::$dbd";
    plan skip_all => "DBD::$dbd required for these tests"
      if $@;
    &$sub();
  };
}

test_with_dbd Mock => sub {
  # DBD::Mock 1.39 does not define table_info which throws an undefined error (RT #68101)
  no warnings 'once';
  local *DBD::Mock::db::table_info = sub { $_[0]->prepare('SELECT table_info()'); };
  use warnings;

  foreach my $trans ( 0, 1 )
  {
    my $dbh = mock_dbh();
    results_for_empty_schema($dbh, $trans);

    my $schema = Test_Schema->new(dbh => $dbh, transactions => $trans);
    my $history = $dbh->{mock_all_history};

    # 5 for schema initialization
    # 2 statements plus 1 version increase in first update
    # 1 statement  plus 1 for second
    is(@$history, 5 + 3 + 2 + (3 * 2 * $trans), 'expected number of statements')
      or diag explain $history;

    is($history->[ 6 + ($trans * 2 * 2) - $trans]->{statement}, q[INSERT INTO tbl1 VALUES('goo', 1)], '1st update');
    is($history->[ 8 + ($trans * 2 * 3) - $trans]->{statement}, q[INSERT INTO tbl1 VALUES('ber', 2)], '2nd update');
  }

  {
    my $dbh = mock_dbh();
    results_for_existing_schema($dbh, 1);

    my $schema = Test_Schema->new(dbh => $dbh);
    my $history = $dbh->{mock_all_history};

    # 2 for existing schema check
    # 1 statement  plus 1 + 2 for second update
    is(@$history, 2 + 4, 'expected number of statements')
      or diag explain $history;

    is($history->[ 3]->{statement}, q[INSERT INTO tbl1 VALUES('ber', 2)], '2nd update');
  }
};

test_with_dbd SQLite => sub {
  {
    my $dbh = DBI->connect('dbi:SQLite:dbname=:memory:');
    my $schema = Test_Schema->new(dbh => $dbh);
    is_deeply($dbh->selectall_arrayref('SELECT * FROM tbl1'), [[qw(goo 1)], [qw(ber 2)]], 'expected rows');
  }

  {
    my $dbh = DBI->connect('dbi:SQLite:dbname=:memory:');
    my $schema = Test_Schema->new(dbh => $dbh, auto_update => 0);

    # remove 2nd update so the schema stops after the 1st
    my $up2 = pop(@{ $schema->updates });
    $schema->up_to_date;
    is_deeply($dbh->selectall_arrayref('SELECT * FROM tbl1'), [[qw(goo 1)]], 'expected rows');

    # put it back
    push(@{ $schema->updates }, $up2);
    $schema->up_to_date;
    is_deeply($dbh->selectall_arrayref('SELECT * FROM tbl1'), [[qw(goo 1)], [qw(ber 2)]], 'expected rows');
  }
};

done_testing;

sub mock_dbh {
  DBI->connect('dbi:Mock:', '', '') or die "Oops: $DBI::errstr";
}

my @table_info_columns = qw(TABLE_CAT TABLE_SCHEM TABLE_NAME TABLE_TYPE REMARKS);

sub results_for_empty_schema {
  my ($dbh, $trans) = @_;
  # table_info (first is empty)
  $dbh->{mock_add_resultset} = [
    [@table_info_columns],
  ];
  # initialize
  $dbh->{mock_add_resultset} = []
    for 1 .. (2 + (2 * $trans)); # create, insert + (begin, commit)
  results_for_existing_schema($dbh, 0);
}

sub results_for_existing_schema {
  my ($dbh, $version) = @_;
  $version ||= 0;
  # table_info
  $dbh->{mock_add_resultset} = [
    [@table_info_columns],
    [qw(mock mock), Test_Schema->version_table_name, 'TABLE', '']
  ];
  # check version
  $dbh->{mock_add_resultset} = [
    ['version'],
    [$version],
  ];
}
