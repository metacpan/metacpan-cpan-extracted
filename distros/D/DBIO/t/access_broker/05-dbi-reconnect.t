# ABSTRACT: AccessBroker reconnect refresh test
use strict;
use warnings;

use Test::More;

use DBIO::Storage::DBI;

{
  package TestBroker;
  use base 'DBIO::AccessBroker';

  sub new {
    bless { calls => 0 }, shift;
  }

  sub connect_info_for {
    my ($self, $mode) = @_;
    my $call = ++$self->{calls};

    return [
      "dbi:SQLite:dbname=:memory:$call",
      "user_$call",
      "pass_$call",
      {},
    ];
  }
}

{
  package TestDBH;

  sub new {
    bless {
      Active     => 1,
      AutoCommit => 1,
      RaiseError => 1,
    }, shift;
  }

  sub FETCH {
    my ($self, $key) = @_;
    return $self->{$key};
  }
}

my $broker = TestBroker->new;
my $storage = DBIO::Storage::DBI->new(undef);

$storage->connect_info([$broker]);

require DBI;

my @connect_calls;
{
  no warnings 'redefine';
  local *DBI::connect = sub {
    push @connect_calls, [@_];
    return TestDBH->new;
  };

  my $dbh1 = $storage->_connect;
  my $dbh2 = $storage->_connect;

  isa_ok $dbh1, 'TestDBH', 'first broker-backed connect returns fake handle';
  isa_ok $dbh2, 'TestDBH', 'second broker-backed connect returns fake handle';
}

is scalar(@connect_calls), 2, 'DBI connect invoked for each connection attempt';
is $connect_calls[0][1], 'dbi:SQLite:dbname=:memory:2',
  'first DBI connect uses freshly fetched broker DSN';
is $connect_calls[1][1], 'dbi:SQLite:dbname=:memory:3',
  'second DBI connect fetches broker DSN again';
is $connect_calls[0][2], 'user_2', 'first DBI connect uses fresh broker username';
is $connect_calls[1][2], 'user_3', 'second DBI connect uses refreshed broker username';
is $broker->{calls}, 3, 'broker was consulted on initial normalize and both connects';
is_deeply(
  $storage->_dbi_connect_info,
  [
    'dbi:SQLite:dbname=:memory:3',
    'user_3',
    'pass_3',
    {
      AutoCommit         => 1,
      PrintError         => 0,
      RaiseError         => 1,
      ShowErrorStatement => 1,
    },
  ],
  'storage keeps the most recent broker-derived DBI connect info',
);

done_testing;
