use strict;
use warnings;

use Test::More;

use DBI;
use DBIO::Storage::DBI;
use DBIO::AccessBroker;
use DBIO::Sybase::Storage;
use DBIO::Sybase::Storage::ASE;

# OFFLINE (karr k87, k66; core karr k276). A DBIO::AccessBroker::HostBound
# view binds its host (and port) into a DBI-form answer through the seam
# DBIO::Storage::DBI->_bind_host_into_dsn($driver, $dsn, $host, $port): the
# DSN, or (undef, $form) when the DSN names its server in a way the seam
# cannot translate. This is the counterpart of core's
# t/access_broker/28-hostbound-dsn-dialects.t for this driver. It claims:
#
#   1. the key form of DBD::Sybase, host=/port=, is what core's default
#      translates (dbdimp.c reads exactly those two): replaced where they
#      stand, put in front where they are missing, database= and everything
#      else untouched;
#   2. server=NAME names an entry of the interfaces file or freetds.conf, not
#      a host, so there is nothing to replace: the seam declines it, and the
#      form it names points at host=/port=. It never quotes the DSN (a
#      password may stand in it) or the view's host;
#   3. the seam is reached on the declared class, on ::ASE and on a storage
#      composed over them, and a HostBound view over such a storage connects
#      to the view's host -- or is refused, DBI->connect never called with
#      the server of the answer;
#   4. a lone host or a lone port of connection PARAMETERS still throws
#      (karr k66, maintainer's decision): DBD::Sybase would drop the lone part
#      and go to the $DSQUERY server. This is the other side of the same
#      coin as 2. Only the POD of the seam says why; the code is unchanged.
#
# No database; DBI->connect is replaced by a recorder.

delete @ENV{qw( DBI_DSN DBI_DRIVER )};

{
  package T::Broker;
  use base 'DBIO::AccessBroker';
  sub new { bless { answer => $_[1] }, $_[0] }
  sub connect_info_for { $_[0]{answer} }
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

my ($H, $P) = ('replica.example', 6000);
my @CLASSES = qw(DBIO::Sybase::Storage DBIO::Sybase::Storage::ASE);

sub seam {
  my ($class, $dsn, $host, $port) = @_;
  return $class->_bind_host_into_dsn('Sybase', $dsn, $host // $H, $port);
}

# ---------------------------------------------------------------- 1. host=/port=
for my $class (@CLASSES) {
  is_deeply [ seam($class, 'dbi:Sybase:host=master.example;port=5000;database=d', $H, $P) ],
    [ "dbi:Sybase:host=$H;port=$P;database=d" ],
    "$class: host= and port= are replaced where they stand";

  is_deeply [ seam($class, 'dbi:Sybase:database=d', $H, $P) ],
    [ "dbi:Sybase:port=$P;host=$H;database=d" ],
    "$class: missing host= and port= are put in front, database= stays";

  is_deeply [ seam($class, 'dbi:Sybase:HOST=master.example;PORT=5000', $H, $P) ],
    [ "dbi:Sybase:host=$H;port=$P" ],
    "$class: the keys are read whatever their case";

  is_deeply [ seam($class, 'dbi:Sybase:host=master.example;port=5000;database=d', $H) ],
    [ "dbi:Sybase:host=$H;port=5000;database=d" ],
    "$class: a view without a port leaves the answer's port";
}

# ---------------------------------------------------------------- 2. server=
for my $class (@CLASSES) {
  for my $dsn (
    'dbi:Sybase:server=MASTER;database=d',
    'dbi:Sybase:database=d;SERVER=MASTER',
    'dbi:Sybase:server=MASTER;host=master.example;port=5000',
  ) {
    my @r = seam($class, $dsn, $H, $P);
    ok !defined $r[0], "$class: '$dsn' is declined";
    like $r[1] // '', qr/\bserver\b/i, '... naming the form';
    like $r[1] // '', qr/host=.*port=/s, '... and pointing at host= and port=';
    unlike $r[1] // '', qr/MASTER|master\.example|\Q$H\E/, '... quoting neither the DSN nor the view\'s host';
  }
}

# a DSN of another DBD is not judged by this driver's server= rule: the next
# seam of the class (dbio-mssql's, for ::MSSQL::Storage::Sybase) answers it
{
  my $called = 0;
  {
    package T::Next;
    use base 'DBIO::Storage::DBI';
    sub _bind_host_into_dsn { $called++; return ('next-answer') }
    package T::Sybase::Over;
    our @ISA = ('DBIO::Sybase::Storage', 'T::Next');
    use mro 'c3';
  }
  my @r = T::Sybase::Over->_bind_host_into_dsn('ODBC', 'dbi:ODBC:Server=MASTER,1433', $H, $P);
  ok $called, 'an ODBC DSN with Server= is passed on to the next seam, not judged here';
}

# ---------------------------------------------------------------- 3. through a storage
sub connect_through {
  my ($storage, $view) = @_;
  return eval { $storage->connect_info([ $view ]); $storage->_connect; 1 } ? undef : "$@";
}

for my $class (@CLASSES) {
  local @CONNECTS;
  my $view = T::Broker->new([ 'dbi:Sybase:host=master.example;port=5000;database=d', 'k87-user', 'k87-pw', {} ])
    ->for_host({ host => $H, port => $P });
  my $error = connect_through($class->new(undef), $view);

  ok !defined $error, "$class: a view over a host=/port= answer connects" or diag $error;
  is $CONNECTS[0][0], "dbi:Sybase:host=$H;port=$P;database=d", '... to the view\'s host and port';
  is_deeply [ @{ $CONNECTS[0] }[1, 2] ], [ 'k87-user', 'k87-pw' ], '... with the credentials of the answer';
}

for my $class (@CLASSES) {
  local @CONNECTS;
  my $view = T::Broker->new([ 'dbi:Sybase:server=MASTER;database=d', 'k87-user', 'k87-pw', {} ])
    ->for_host({ host => $H, port => $P });
  my $error = connect_through($class->new(undef), $view);

  ok defined $error, "$class: a view over a server= answer is refused";
  like $error // '', qr/server/, '... naming the form';
  like $error // '', qr/host=.*port=/s, '... and pointing at host= and port=';
  unlike $error // '', qr/MASTER|k87-|\Q$H\E/, '... quoting neither the DSN, a credential nor the view\'s host';
  is scalar @CONNECTS, 0, '... and DBI->connect is never called';
}

# ---------------------------------------------------------------- 4. karr k66
for my $case (
  [ 'host without port', { host => 'h.example' },  qr/host without a port/ ],
  [ 'port without host', { port => 5000 },         qr/port without a host/ ],
) {
  my ($label, $params, $like) = @$case;
  for my $class (@CLASSES) {
    my $dsn = eval { $class->_connect_params_dsn('Sybase', $params) };
    ok !defined $dsn, "$class: $label still throws";
    like "$@", $like, '... naming the combination';
    like "$@", qr/DBD::Sybase.*ignor/s, '... and that DBD::Sybase would drop the lone part';
  }
}

done_testing;
