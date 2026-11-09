# ABSTRACT: _finish_connect_dsn is the driver's last word on the DSN of every connect
use strict;
use warnings;

use Test::More;

use DBI;
use DBIO::Storage::DBI;
use DBIO::AccessBroker::Static;

# OFFLINE (karr k361). With a broker, _connect forms the DSN anew from the
# broker's answer at every connection, so what a driver appended to the stored
# DSN (dbio-sybase: ';maxConnect=N', ';bulkLogin=1') never reached
# DBI->connect. The named seam _finish_connect_dsn($dsn) is asked for the DSN
# string of every connect, broker or not, after the connect info is formed.
#
# What this file claims:
#   1. a storage overriding the seam sees its addition at DBI->connect --
#      static connect info, a broker answering a whole DSN, a broker answering
#      dbname/host/port -- and again at a reconnect;
#   2. the stored connect info is not mutated (the seam is idempotent by
#      contract: it runs for every connect);
#   3. the default seam leaves the DSN as it is;
#   4. a connection coderef never goes through the seam.

delete @ENV{qw( DBI_DSN DBI_DRIVER )};

{
  package T::Plain::Storage;
  use base 'DBIO::Storage::DBI';
  DBIO::Storage::DBI->register_driver(ExampleP => __PACKAGE__);
}

{
  package T::Finish::Storage;
  use base 'T::Plain::Storage';
  our @ASKED;
  sub _finish_connect_dsn {
    my ($self, $dsn) = @_;
    push @ASKED, $dsn;
    return $dsn =~ /;x=1\z/ ? $dsn : "$dsn;x=1";
  }
}

{
  package T::Handle;
  sub new   { bless { Active => 1, AutoCommit => 1, RaiseError => 1 }, shift }
  sub FETCH { $_[0]->{ $_[1] } }
}

our @CONNECTS;
{
  no warnings 'redefine';
  *DBI::connect = sub { shift; push @CONNECTS, [ @_ ]; T::Handle->new };
}

my $WHOLE = 'dbi:ExampleP:dbname=k361-db';

my %FORM = (
  'no broker'         => sub { [ $WHOLE, 'u', 'p' ] },
  'broker, whole DSN' => sub {
    [ DBIO::AccessBroker::Static->new(dbname => $WHOLE, username => 'u', password => 'p') ]
  },
  'broker, dbname/host/port' => sub {
    [ DBIO::AccessBroker::Static->new(
      dbname => 'k361-db', host => 'h', port => 5, username => 'u', password => 'p',
    ) ]
  },
);
my %PLAIN_DSN = (
  'no broker'                => $WHOLE,
  'broker, whole DSN'        => $WHOLE,
  'broker, dbname/host/port' => 'dbi:ExampleP:dbname=k361-db;host=h;port=5',
);

for my $label (sort keys %FORM) {
  {
    my $plain = T::Plain::Storage->new(undef);
    $plain->connect_info($FORM{$label}->());
    local @CONNECTS;
    $plain->_connect;
    is $CONNECTS[0][0], $PLAIN_DSN{$label}, "$label: the default seam leaves the DSN alone";
  }

  my $storage = T::Finish::Storage->new(undef);
  $storage->connect_info($FORM{$label}->());
  local @CONNECTS;
  $storage->_connect;
  is $CONNECTS[0][0], "$PLAIN_DSN{$label};x=1", "$label: DBI->connect sees the seam's DSN";
  $storage->_connect;
  is $CONNECTS[1][0], "$PLAIN_DSN{$label};x=1", "$label: and again at a reconnect, once";
  is $storage->_dbi_connect_info->[0], $PLAIN_DSN{$label},
    "$label: the stored connect info is not mutated";
}

{
  my $storage = T::Finish::Storage->new(undef);
  $storage->connect_info([ sub { T::Handle->new } ]);
  local @T::Finish::Storage::ASKED;
  $storage->_connect;
  is scalar @T::Finish::Storage::ASKED, 0, 'a connection coderef never goes through the seam';
}

done_testing;
