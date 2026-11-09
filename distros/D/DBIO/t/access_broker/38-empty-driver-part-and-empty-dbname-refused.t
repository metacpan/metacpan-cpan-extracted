# ABSTRACT: a DSN without a driver part and a hash with an empty dbname are refused
use strict;
use warnings;

use Test::More;
use Test::Exception;

use DBI;
use DBIO::Schema;
use DBIO::Storage::DBI;
use DBIO::AccessBroker;

# OFFLINE (karr k340, remainder of k306; maintainer's decision 2026-10-13).
#
# WHY: the DSN decides the driver. A DSN whose driver part is empty
# (dbi::dbname=x) names none, and $ENV{DBI_DRIVER} is no substitute for it --
# the environment of the process would pick the driver the user's connect info
# goes to. A hash whose dbname is empty names no database: the DSN built from it
# would connect to whatever the server defaults to.
#
# What this file claims:
#   1. A DSN with an empty driver part is refused where the driver is
#      determined, naming the shape, with $ENV{DBI_DRIVER} set or not, on the
#      generic storage and on a driver's, static and through a broker.
#      DBI->connect is never reached.
#   2. A hash with an empty dbname is refused where its DSN is built, static
#      and through a broker, with host and port beside it or not. A dbname that
#      is not given (undef, with host) still builds the DSN (control).

delete @ENV{qw( DBI_DSN DBI_DRIVER )};

{
  package T::Driver::Storage;
  use base 'DBIO::Storage::DBI';
  DBIO::Storage::DBI->register_driver(K340Fake => __PACKAGE__);
}

{
  package T::Handle;
  sub new   { bless { Active => 1, AutoCommit => 1, RaiseError => 1 }, shift }
  sub FETCH { $_[0]->{ $_[1] } }
}

{
  package T::Broker;
  use base 'DBIO::AccessBroker';
  sub new { my ($class, $answer) = @_; bless { answer => $answer }, $class }
  sub connect_info_for { $_[0]{answer}->() }
}

our @CONNECTS;
{
  no warnings 'redefine';
  *DBI::connect = sub { shift; push @CONNECTS, [ @_ ]; T::Handle->new };
}

my @STORAGES = ('DBIO::Storage::DBI', 'T::Driver::Storage');

# 1. empty driver part
for my $class (@STORAGES) {
  for my $env (undef, 'K340Fake') {
    for my $case (
      [ 'static' => sub { [ 'dbi::dbname=k340', 'u', 'p' ] } ],
      [ 'broker' => sub { [ T::Broker->new(sub { [ 'dbi::dbname=k340', 'u', 'p' ] }) ] } ],
    ) {
      my ($how, $info) = @$case;
      my $t = "$class, $how, DBI_DRIVER " . ($env // 'unset');
      local $ENV{DBI_DRIVER} = $env if defined $env;
      local @CONNECTS;

      my $storage = $class->new(undef);
      my $failed = !eval { $storage->connect_info($info->()); $storage->ensure_connected; 1 };
      ok $failed, "$t: refused";
      like "$@", qr/DSN without a driver part/, "$t: naming the shape";
      unlike "$@", qr/k340/, "$t: naming no value";
      is scalar @CONNECTS, 0, "$t: DBI->connect is not called";
    }
  }
}

# 2. empty dbname
for my $case (
  [ 'dbname empty'            => { dbname => '' } ],
  [ 'dbname empty, host+port' => { dbname => '', host => 'k340-host', port => 5432 } ],
) {
  my ($name, $hash) = @$case;
  for my $how (qw(static broker)) {
    my $t = "T::Driver::Storage, $how, $name";
    local @CONNECTS;
    my $storage = T::Driver::Storage->new(undef);
    my $info = $how eq 'static'
      ? [ { %$hash, user => 'u', password => 'p' } ]
      : [ T::Broker->new(sub { +{ %$hash, user => 'u', password => 'p' } }) ];
    throws_ok { $storage->connect_info($info); $storage->_connect }
      qr/empty dbname/, "$t: refused, naming the key";
    unlike "$@", qr/k340-host/, "$t: naming no value";
    is scalar @CONNECTS, 0, "$t: DBI->connect is not called";
  }
}

{
  local @CONNECTS;
  my $storage = T::Driver::Storage->new(undef);
  lives_ok {
    $storage->connect_info([ { dbname => undef, host => 'k340-host', user => 'u' } ]);
    $storage->_connect;
  } 'dbname undef beside a host still builds the DSN (control)';
  is $CONNECTS[0][0], 'dbi:K340Fake:host=k340-host', '... from the parts given';
}

done_testing;
