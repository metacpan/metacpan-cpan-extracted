use strict;
use warnings;

use Test::More;

use DBI;
use DBIO::Storage::DBI;
use DBIO::DB2::Storage;
use DBIO::AccessBroker;

# OFFLINE (karr k50; core k276). A DBIO::AccessBroker::HostBound view puts its
# host (and port) into the DSN of the answer it wraps, through the storage's
# seam _bind_host_into_dsn. Core's default knows host=/port= only and declines
# DB2's HOSTNAME=; this driver overrides the seam.
#
#   1. HOSTNAME= and PORT= are replaced where they stand, whatever their case;
#      the rest of the DSN does not change;
#   2. a view with a port and a DSN without PORT= gets PORT= after HOSTNAME=;
#      a view without a port leaves the DSN's PORT=;
#   3. a form that cannot be translated -- the cataloged alias, a part that is
#      not key=value, a DSN without dbi:DB2: -- is declined naming the form,
#      never a value of the DSN;
#   4. end to end: a HostBound view over a DB2 storage connects with the
#      replicant's host (DBI->connect is mocked and records the DSN), and a
#      cataloged alias is refused before any connect.

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

sub bind_it { DBIO::DB2::Storage->_bind_host_into_dsn('DB2', @_) }

# 1 + 2
for my $case (
  [ 'HOSTNAME and PORT replaced',
    'dbi:DB2:DATABASE=d;HOSTNAME=master.example;PORT=50000;PROTOCOL=TCPIP', 'replica.example', 50001,
    'dbi:DB2:DATABASE=d;HOSTNAME=replica.example;PORT=50001;PROTOCOL=TCPIP' ],
  [ 'lower-case keys keep their spelling',
    'dbi:DB2:database=d;hostname=master.example;port=50000;protocol=tcpip', 'replica.example', 50001,
    'dbi:DB2:database=d;hostname=replica.example;port=50001;protocol=tcpip' ],
  [ 'a view without a port leaves PORT=',
    'dbi:DB2:DATABASE=d;HOSTNAME=master.example;PORT=50000;PROTOCOL=TCPIP', 'replica.example', undef,
    'dbi:DB2:DATABASE=d;HOSTNAME=replica.example;PORT=50000;PROTOCOL=TCPIP' ],
  [ 'a view port and no PORT= puts PORT= after HOSTNAME=',
    'dbi:DB2:DATABASE=d;HOSTNAME=master.example;PROTOCOL=TCPIP', 'replica.example', 50001,
    'dbi:DB2:DATABASE=d;HOSTNAME=replica.example;PORT=50001;PROTOCOL=TCPIP' ],
  [ 'HOSTNAME first, trailing ;',
    'DBI:DB2:HOSTNAME=master.example;DATABASE=d;', 'replica.example', undef,
    'DBI:DB2:HOSTNAME=replica.example;DATABASE=d;' ],
) {
  my ($label, $dsn, $host, $port, $expected) = @$case;
  my @r = bind_it($dsn, $host, $port);
  is_deeply \@r, [ $expected ], $label;
}

# 3
for my $case (
  [ 'cataloged alias',     'dbi:DB2:testdb',                   qr/cataloged/ ],
  [ 'no HOSTNAME=',        'dbi:DB2:DATABASE=d;PORT=50000',    qr/HOSTNAME/ ],
  [ 'positional part',     'dbi:DB2:HOSTNAME=h;secretpart',    qr/key=value/ ],
  [ 'no dbi:DB2: prefix',  'master.example',                   qr/dbi:Driver:/ ],
) {
  my ($label, $dsn, $form) = @$case;
  my @r = bind_it($dsn, 'replica.example', 50001);
  ok !defined $r[0], "$label: declined";
  like $r[1] // '', $form, '... naming the form';
  unlike $r[1] // '', qr/testdb|secretpart|master\.example|DATABASE=d|replica\.example/,
    '... quoting no value of the DSN';
}

# 4
sub connect_through {
  my ($dsn) = @_;
  my $view = T::Broker->new([ $dsn, 'k50-user', 'k50-pw', {} ])
    ->for_host({ host => 'replica.example', port => 50001 });
  my $storage = DBIO::DB2::Storage->new(undef);
  return eval { $storage->connect_info([ $view ]); $storage->_connect; 1 } ? undef : "$@";
}

{
  local @CONNECTS;
  my $error = connect_through('dbi:DB2:DATABASE=d;HOSTNAME=master.example;PORT=50000;PROTOCOL=TCPIP');
  ok !defined $error, 'a HostBound view over a DB2 storage connects' or diag $error;
  is $CONNECTS[0][0], 'dbi:DB2:DATABASE=d;HOSTNAME=replica.example;PORT=50001;PROTOCOL=TCPIP',
    "... to the view's host and port";
  is_deeply [ @{ $CONNECTS[0] }[1, 2] ], [ 'k50-user', 'k50-pw' ], '... with the answer\'s credentials';
}

{
  local @CONNECTS;
  my $error = connect_through('dbi:DB2:testdb');
  ok defined $error, 'a view over a cataloged alias is refused';
  like $error // '', qr/cataloged/, '... naming the form';
  unlike $error // '', qr/testdb|k50-/, '... quoting neither the alias nor a credential';
  is scalar @CONNECTS, 0, '... and nothing is connected';
}

done_testing;
