use strict;
use warnings;
use Test::More;

use DBI;
use DBIO::AccessBroker;
use DBIO::Firebird::Storage;
use DBIO::Firebird::Storage::InterBase;
use DBIO::Firebird::Storage::ODBC;

# OFFLINE (karr k50, core k276).
#
# WHY: a DBIO::AccessBroker::HostBound view (DBIO::Replicated: one credential,
# a host per replicant) puts its host into the broker's DSN, and how a DSN
# names its server is the DBD's business -- the storage's seam
# _bind_host_into_dsn. Core's default knows host= and port= and refuses
# db=host:path (and hostname=); db=/path;host=... and a local name it
# translates. Firebird takes the server in the database name
# (db=host[/port]:path), in host=/hostname= (the port inside, h/3050, or in
# port=), or not at all (a local file). Left to the default, the common form
# db=host:path is refused, and a view could not be used with that form of
# this driver; and an ODBC DSN would get a host= its driver ignores, the replicant
# connecting to whatever the database name says.
#
# What this file claims:
#   1. Each of the three forms is bound where the answer has the server, the
#      other parts of the DSN untouched, a view without a port leaving the
#      answer's, a view port replacing it.
#   2. What is not translated is refused naming the form (host/service:path,
#      a service name in host= that a view without a port would drop, an IPv6
#      database name, a drive-relative path), never the DSN, the
#      credentials or the view's host.
#   3. Through a storage the connection goes to the view's host: DBI->connect
#      is never handed the answer's server.
#   4. The ODBC storage declines every DSN.
#
# THE SUBSTITUTIONS: DBI->connect is a recorder returning a stand-in handle.

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
  sub get_info { 0 }
}

our @CONNECTS;
{
  no warnings 'redefine';
  *DBI::connect = sub { shift; push @CONNECTS, [ @_ ]; T::Handle->new };
}

my $NATIVE = 'DBIO::Firebird::Storage';

sub bind_seam {
  my ($class, $dsn, $host, $port) = @_;
  return $class->new(undef)->_bind_host_into_dsn(($dsn =~ /\Adbi:([^:(]*)/i)[0] // '', $dsn, $host, $port);
}

# ---------------------------------------------------------------------------
# 1. The three forms.
# ---------------------------------------------------------------------------
for my $class ($NATIVE, 'DBIO::Firebird::Storage::InterBase') {
  for my $case (
    # label, DSN, view host, view port, expected
    [ 'db=host:path, no port',
      'dbi:Firebird:db=master:/data/app.fdb;ib_charset=UTF8', 'replica', undef,
      'dbi:Firebird:db=replica:/data/app.fdb;ib_charset=UTF8' ],
    [ 'db=host/port:path, the view without a port keeps the answer\'s',
      'dbi:Firebird:db=master/3051:/data/app.fdb', 'replica', undef,
      'dbi:Firebird:db=replica/3051:/data/app.fdb' ],
    [ 'db=host/port:path, a view port replaces it',
      'dbi:Firebird:db=master/3051:/data/app.fdb', 'replica', 3060,
      'dbi:Firebird:db=replica/3060:/data/app.fdb' ],
    [ 'dbname=host:path gets a port',
      'dbi:Firebird:dbname=master:/data/app.fdb', 'replica', 3060,
      'dbi:Firebird:dbname=replica/3060:/data/app.fdb' ],
    [ 'database= and upper-case keys',
      'DBI:Firebird:DATABASE=master:/data/app.fdb', 'replica', undef,
      'DBI:Firebird:DATABASE=replica:/data/app.fdb' ],
    [ 'a Windows path behind the host',
      'dbi:Firebird:db=master:C:\data\app.fdb', 'replica', undef,
      'dbi:Firebird:db=replica:C:\data\app.fdb' ],
    [ 'host= token replaced where it stands',
      'dbi:Firebird:dbname=/data/app.fdb;host=master;ib_charset=UTF8', 'replica', undef,
      'dbi:Firebird:dbname=/data/app.fdb;host=replica;ib_charset=UTF8' ],
    [ 'host=h/port: the view without a port keeps the answer\'s',
      'dbi:Firebird:dbname=/data/app.fdb;host=master/3051', 'replica', undef,
      'dbi:Firebird:dbname=/data/app.fdb;host=replica/3051' ],
    [ 'host=h/port: a view port goes to port= and out of the host',
      'dbi:Firebird:dbname=/data/app.fdb;host=master/3051', 'replica', 3060,
      'dbi:Firebird:dbname=/data/app.fdb;host=replica;port=3060' ],
    [ 'host=h/service: a view port replaces the service with port=',
      'dbi:Firebird:dbname=/data/app.fdb;host=master/fb_inst2', 'replica', 3060,
      'dbi:Firebird:dbname=/data/app.fdb;host=replica;port=3060' ],
    [ 'a drive path (C:\\...) is a local path, not a host',
      'dbi:Firebird:db=C:\data\app.fdb', 'replica', undef,
      'dbi:Firebird:host=replica;db=C:\data\app.fdb' ],
    [ 'hostname= and port= replaced where they stand',
      'dbi:Firebird:hostname=master;port=3051;db=/data/app.fdb', 'replica', 3060,
      'dbi:Firebird:hostname=replica;port=3060;db=/data/app.fdb' ],
    [ 'hostname=, the answer\'s port= stays without a view port',
      'dbi:Firebird:hostname=master;port=3051;db=/data/app.fdb', 'replica', undef,
      'dbi:Firebird:hostname=replica;port=3051;db=/data/app.fdb' ],
    [ 'a local path: host= put in front',
      'dbi:Firebird:dbname=/data/app.fdb', 'replica', undef,
      'dbi:Firebird:host=replica;dbname=/data/app.fdb' ],
    [ 'a local path: host= and port= put in front',
      'dbi:Firebird:dbname=/data/app.fdb;ib_dialect=3', 'replica', 3060,
      'dbi:Firebird:host=replica;port=3060;dbname=/data/app.fdb;ib_dialect=3' ],
    [ 'a local path with a port= but no host',
      'dbi:Firebird:dbname=/data/app.fdb;port=3051', 'replica', 3060,
      'dbi:Firebird:host=replica;dbname=/data/app.fdb;port=3060' ],
    [ 'an alias',
      'dbi:Firebird:db=billing', 'replica', undef,
      'dbi:Firebird:host=replica;db=billing' ],
    [ 'DBD::InterBase',
      'dbi:InterBase:db=master:/data/app.fdb', 'replica', undef,
      'dbi:InterBase:db=replica:/data/app.fdb' ],
    [ 'attributes in the prefix',
      'dbi:Firebird(RaiseError=1):db=master:/data/app.fdb', 'replica', undef,
      'dbi:Firebird(RaiseError=1):db=replica:/data/app.fdb' ],
    [ 'a part split over lines',
      "dbi:Firebird:\n  dbname=/data/app.fdb;\n  host=master\n", 'replica', undef,
      "dbi:Firebird:\n  dbname=/data/app.fdb;host=replica" ],
  ) {
    my ($label, $dsn, $host, $port, $expected) = @$case;
    my ($got, $form) = bind_seam($class, $dsn, $host, $port);
    is $got, $expected, "$class: $label" or diag $form;
    unlike $got // '', qr/master/, '... the answer\'s host is gone';
  }
}

# ---------------------------------------------------------------------------
# 2. Refused, naming the form.
# ---------------------------------------------------------------------------
for my $case (
  [ 'a part without key=value',  'dbi:Firebird:master-server',                         qr/without key=value form/ ],
  [ 'a DSN without a prefix',    'master-server',                                      qr/without a dbi:Driver: prefix/ ],
  [ 'no database key',           'dbi:Firebird:host=master-server',                    qr/no db, dbname or database key/ ],
  [ 'two database keys',         'dbi:Firebird:db=/a.fdb;dbname=/b.fdb',               qr/more than one of the keys db, dbname and database/ ],
  [ 'two host keys',             'dbi:Firebird:db=/a.fdb;host=master-server;hostname=m2', qr/more than one of the keys host and hostname/ ],
  [ 'a host in both places',     'dbi:Firebird:db=master-server:/a.fdb;host=m2',       qr/host in both the key 'db' and a host key/ ],
  [ 'a port= beside db=host:',   'dbi:Firebird:db=master-server:/a.fdb;port=3051',     qr/port key beside a host in the key 'db'/ ],
  [ 'a URL-style database name', 'dbi:Firebird:db=inet://master-server/a.fdb',         qr/'db' with a URL-style database name/ ],
  [ 'host/service:path',         'dbi:Firebird:db=master-server/gds_db:/a.fdb',        qr/service name after the host in the key 'db'/ ],
  [ 'host= with a service name and a view without a port',
                                 'dbi:Firebird:db=/a.fdb;host=master-server/fb_inst2', qr/service name in the key 'host' and a view without a port/ ],
  [ 'an IPv6 database name',     'dbi:Firebird:db=[::1]:/a.fdb',                       qr/IPv6 address in the key 'db'/ ],
  [ 'a drive-relative path',     'dbi:Firebird:db=C:data.fdb',                         qr/drive-relative path in the key 'db'/ ],
  [ 'another DBD',               'dbi:ODBC:Driver=Firebird;Dbname=master-server:/a.fdb', qr/DSN of the DBD 'ODBC'/ ],
) {
  my ($label, $dsn, $form) = @$case;
  my ($got, $declined) = bind_seam($NATIVE, $dsn, 'replica-secret', undef);
  ok !defined $got, "$label: declined";
  like $declined // '', $form, '... naming the form';
  unlike $declined // '', qr/master|replica-secret/, '... quoting neither the DSN nor the view\'s host';
}

for my $host ('a:b', 'a/b', 'a b') {
  my ($got, $declined) = bind_seam($NATIVE, 'dbi:Firebird:db=/a.fdb', $host);
  ok !defined $got, "a view host '$host': declined";
  like $declined // '', qr/a view host with a colon, slash or space/, '... naming the form';
}

# ---------------------------------------------------------------------------
# 3. Through a storage: where the connection goes.
# ---------------------------------------------------------------------------
sub connect_through {
  my ($class, $answer, $host) = @_;
  my $storage = $class->new(undef);
  my $view = T::Broker->new($answer)->for_host($host);
  local @CONNECTS;
  my $error = eval { $storage->connect_info([ $view ]); $storage->_connect; 1 } ? undef : "$@";
  return ($error, [ @CONNECTS ]);
}

{
  my ($error, $connects) = connect_through($NATIVE,
    [ 'dbi:Firebird:db=master-host:/data/app.fdb', 'k50-user', 'k50-secret', {} ],
    { host => 'replica-host', port => 3060 });
  ok !defined $error, 'a view over a db=host:path answer: the storage connects' or diag $error;
  like $connects->[0][0] // '', qr{\Adbi:Firebird:db=replica-host/3060:/data/app\.fdb(?:;ib_dialect=3)?(?:;ib_charset=UTF8)?\z},
    '... to the view\'s host (the answer\'s master is not in the DSN)';
  unlike $connects->[0][0] // '', qr/master-host/, '... never the answer\'s';
  is_deeply [ @{ $connects->[0] }[1, 2] ], [ 'k50-user', 'k50-secret' ], '... with the answer\'s credentials';
}

{
  my ($error, $connects) = connect_through($NATIVE,
    { dsn => 'dbi:Firebird:dbname=/data/app.fdb;host=master-host', user => 'k50-user', password => 'k50-secret' },
    { host => 'replica-host' });
  ok !defined $error, 'a view over a hash answer with a dsn: the storage connects' or diag $error;
  like $connects->[0][0] // '', qr/host=replica-host/, '... to the view\'s host';
}

{
  my ($error, $connects) = connect_through($NATIVE,
    [ 'dbi:Firebird:db=inet://master-host/data/app.fdb', 'k50-user', 'k50-secret', {} ],
    { host => 'replica-host' });
  ok defined $error, 'a form the seam declines: the connection is refused';
  like $error // '', qr/URL-style database name/, '... naming the form';
  unlike $error // '', qr/master-host|replica-host|k50-/, '... quoting neither DSN, host nor credential';
  is scalar @$connects, 0, '... and nothing is connected';
}

# ---------------------------------------------------------------------------
# 4. ODBC.
# ---------------------------------------------------------------------------
{
  for my $dsn (
    'dbi:ODBC:Driver=Firebird;Dbname=/data/app.fdb',
    'dbi:ODBC:Driver=Firebird;Dbname=master-host/3050:/data/app.fdb',
  ) {
    my ($got, $declined) = bind_seam('DBIO::Firebird::Storage::ODBC', $dsn, 'replica-host', 3060);
    ok !defined $got, 'the ODBC storage: declined';
    like $declined // '', qr/an ODBC DSN: .*DBNAME=host\/port:path/, '... naming the form';
    unlike $declined // '', qr/master-host|replica-host|data/, '... quoting no value';
  }

  my ($error, $connects) = connect_through('DBIO::Firebird::Storage::ODBC',
    [ 'dbi:ODBC:Driver=Firebird;Dbname=/data/app.fdb', 'k50-user', 'k50-secret', {} ],
    { host => 'replica-host' });
  ok defined $error, 'a view over an ODBC answer: the connection is refused';
  is scalar @$connects, 0, '... and nothing is connected';
}

done_testing;
