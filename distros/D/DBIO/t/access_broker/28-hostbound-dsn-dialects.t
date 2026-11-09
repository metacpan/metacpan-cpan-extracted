# ABSTRACT: A HostBound view over an answer whose server it cannot rewrite
use strict;
use warnings;

use Test::More;
use Test::Exception;

use DBI;
use DBIO::Test;
use DBIO::Test::Storage;
use DBIO::Storage::DBI;
use DBIO::AccessBroker;

# OFFLINE (karr k270, k276). A DBIO::AccessBroker::HostBound view puts its host
# (and port) into the answer of the broker it wraps: one credential, many
# servers. For an answer in DBI form it rewrites the DSN -- and how a DSN names
# its server is a question of the DBD, so the view asks the driver's storage
# class: DBIO::Storage::DBI->_bind_host_into_dsn($driver, $dsn, $host, $port).
# The core default knows one form, a host= and a port= token among
# semicolon-separated key=value pairs after dbi:Driver:; it replaces such a
# token where it stands and puts one in front where there is none. A driver
# that takes its server another way overrides the seam.
#
# What the view and the default cannot bind they REFUSE, naming the form (a
# key, a dialect) and never the DSN or a credential: a replicant given a view
# must not connect to the master of the answer.
#
# What this file claims:
#   1. the form the default knows: host= and port= are replaced where they
#      stand, whatever their case, and put in front where they are missing;
#      nothing else of the DSN changes;
#   2. a DSN naming its server another way -- Easy Connect, TNS, DB2 HOSTNAME=,
#      Sybase server=, ODBC Server=/data source, mysql positional, Firebird
#      db=host:path, libpq hostaddr= -- is refused by the default, naming the
#      form;
#   3. the same through a storage: DBI->connect is never called with the DSN
#      of the answer's server;
#   4. an answer with no DSN text to rewrite -- a coderef, a dbh_maker -- is
#      refused before the code runs; a hash carrying a dsn has its host bound
#      into that DSN and gets no host/port attribute;
#   5. a view's host or port containing ';' is refused before any seam is
#      asked, so a driver never sees it;
#   6. the seam itself: a driver storage that overrides it is asked (through
#      its class, or through the registry while the storage is still the
#      generic class), what it translates is what DBI->connect sees, and what
#      it declines is refused naming its form.
#
# THE SUBSTITUTIONS: brokers answering what they were given; DBI->connect
# records its arguments and returns a stand-in handle; fake driver storages
# registered for the DBD names 'FakeHB', 'FakeSeam' and 'FakeNo'. No database.

delete @ENV{qw( DBI_DSN DBI_DRIVER )};

{
  package T::Broker;
  use base 'DBIO::AccessBroker';
  sub new { bless { answer => $_[1] }, $_[0] }
  sub connect_info_for { $_[0]{answer} }
}

{
  package T::FakeDriver::Storage;
  use base 'DBIO::Test::Storage';
  DBIO::Storage::DBI->register_driver(FakeHB => __PACKAGE__);
}

# A driver whose DSN names the server as server=NAME[,PORT].
{
  package T::Seam::Storage;
  use base 'DBIO::Storage::DBI';
  DBIO::Storage::DBI->register_driver(FakeSeam => __PACKAGE__);
  our @ASKED;
  sub _bind_host_into_dsn {
    my ($self, $driver, $dsn, $host, $port) = @_;
    push @ASKED, [ $driver, $dsn, $host, $port ];
    $dsn =~ s/server=[^;]*/'server=' . $host . (defined $port ? ",$port" : '')/e
      or return (undef, 'a FakeSeam DSN without server=');
    return $dsn;
  }
}

# A driver that binds nothing.
{
  package T::Reject::Storage;
  use base 'DBIO::Storage::DBI';
  DBIO::Storage::DBI->register_driver(FakeNo => __PACKAGE__);
  sub _bind_host_into_dsn { return (undef, 'form X') }
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

my %VIEW = (host => 'replica.example', port => 6000);

sub view_over { my ($answer, $host) = @_; T::Broker->new($answer)->for_host($host || { %VIEW }) }

# The DSN a view over a DBI-form answer hands on, or the error it refused with.
sub bound_dsn {
  my ($dsn, $host, $storage) = @_;
  my $info;
  my $view = view_over([ $dsn, 'u', 'p', {} ], $host);
  return (undef, "$@")
    unless eval { $info = $storage ? $view->connect_info_for_storage($storage) : $view->connect_info_for; 1 };
  return ($info->[0], undef);
}

# Connect a storage through a view; the error, or undef.
sub connect_through {
  my ($storage, $view) = @_;
  return eval { $storage->connect_info([ $view ]); $storage->_connect; 1 } ? undef : "$@";
}

# ---------------------------------------------------------------------------
# 1. The form the view knows.
# ---------------------------------------------------------------------------
for my $case (
  [ 'host= and port= present',
    'dbi:Pg:dbname=app;host=master.example;port=5432',
    'dbi:Pg:dbname=app;host=replica.example;port=6000' ],
  [ 'host= first, other tokens after',
    'dbi:Pg:host=master.example;dbname=app;sslmode=require',
    'dbi:Pg:port=6000;host=replica.example;dbname=app;sslmode=require' ],
  [ 'neither present',
    'dbi:Pg:dbname=app',
    'dbi:Pg:port=6000;host=replica.example;dbname=app' ],
  [ 'nothing after the driver',
    'dbi:Pg:',
    'dbi:Pg:port=6000;host=replica.example' ],
  [ 'upper-case keys',
    'dbi:Pg:dbname=app;HOST=master.example;PORT=5432',
    'dbi:Pg:dbname=app;host=replica.example;port=6000' ],
  [ 'upper-case DBI prefix',
    'DBI:Pg:dbname=app;host=master.example',
    'DBI:Pg:port=6000;dbname=app;host=replica.example' ],
  [ 'driver attributes in the prefix',
    'dbi:Pg(RaiseError=1):dbname=app;host=master.example',
    'dbi:Pg(RaiseError=1):port=6000;dbname=app;host=replica.example' ],
) {
  my ($label, $dsn, $expected) = @$case;
  my ($got, $error) = bound_dsn($dsn);
  is $got, $expected, "$label: the view's host and port are bound into the DSN";
  unlike $got // '', qr/master\.example/, "$label: ... and the answer's host is gone";
}

{
  my ($got) = bound_dsn('dbi:Pg:dbname=app;host=master.example;port=5432', 'replica.example');
  is $got, 'dbi:Pg:dbname=app;host=replica.example;port=5432',
    "a view without a port leaves the answer's port";

  my $info = view_over([ 'dbi:Pg:dbname=app;host=master.example', 'k270-user', 'k270-pw', { PrintWarn => 0 } ])
    ->connect_info_for;
  is_deeply [ @$info[1 .. 3] ], [ 'k270-user', 'k270-pw', { PrintWarn => 0 } ],
    '... and the credentials and attributes of the answer are handed on as they came';
}

# ---------------------------------------------------------------------------
# 2. A DSN that names its server another way: refused, naming the form.
# ---------------------------------------------------------------------------
my @DIALECTS = (
  [ 'Oracle Easy Connect',
    'dbi:Oracle://master.example:1521/svc', qr/master\.example/, qr/without key=value form/ ],
  [ 'Oracle TNS descriptor',
    'dbi:Oracle:(DESCRIPTION=(ADDRESS=(HOST=master.example)(PORT=1521))(CONNECT_DATA=(SID=x)))', qr/master\.example/, qr/without key=value form/ ],
  [ 'DB2 HOSTNAME=',
    'dbi:DB2:DATABASE=d;HOSTNAME=master.example;PORT=50000;PROTOCOL=TCPIP', qr/master\.example/, qr/'HOSTNAME'/ ],
  [ 'Sybase server=',
    'dbi:Sybase:server=MASTER', qr/MASTER/, qr/'server'/ ],
  [ 'ODBC Server=',
    'dbi:ODBC:Driver={ODBC Driver 18};Server=master.example,1433;Database=d', qr/master\.example/, qr/'Server'/ ],
  [ 'ODBC data source name',
    'dbi:ODBC:MASTERDSN', qr/MASTERDSN/, qr/without key=value form/ ],
  [ 'DBD::mysql positional',
    'dbi:mysql:app:master.example:3306', qr/master\.example/, qr/without key=value form/ ],
  [ 'Firebird db=host:path',
    'dbi:Firebird:db=master.example/3050:/data/app.fdb', qr/master\.example/, qr/'db'/ ],
  [ 'libpq hostaddr=',
    'dbi:Pg:dbname=app;hostaddr=10.0.0.1', qr/10\.0\.0\.1/, qr/'hostaddr'/ ],
  [ 'a DSN without dbi:Driver:',
    'master.example', qr/master\.example/, qr/without a dbi:Driver: prefix/ ],
);

for my $case (@DIALECTS) {
  my ($label, $dsn, $server, $form) = @$case;
  my ($got, $error) = bound_dsn($dsn);

  ok !defined $got, "$label: the view hands on no DSN";
  like $error // '', $form, "... and the refusal names the form";
  unlike $error // '', $server, "... without quoting the DSN";
  unlike $error // '', qr/replica\.example/, "... or the view's host";
}

# what stays translatable
for my $case (
  [ 'a local dbname path',   'dbi:Pg:dbname=/var/db/app',   'dbi:Pg:port=6000;host=replica.example;dbname=/var/db/app' ],
  [ 'a Windows drive path',  'dbi:Firebird:db=C:\data\a.fdb', 'dbi:Firebird:port=6000;host=replica.example;db=C:\data\a.fdb' ],
  [ 'a trailing empty part', 'dbi:Pg:dbname=app;',          'dbi:Pg:port=6000;host=replica.example;dbname=app;' ],
) {
  my ($label, $dsn, $expected) = @$case;
  my ($got, $error) = bound_dsn($dsn);
  is $got, $expected, "$label stays translatable";
}

# ---------------------------------------------------------------------------
# 3. Through a storage: where the connection goes.
# ---------------------------------------------------------------------------
{
  my $view = view_over([ 'dbi:DB2:DATABASE=d;HOSTNAME=master.example;PORT=50000', 'k270-user', 'k270-pw', {} ]);
  my $storage = DBIO::Storage::DBI->new(undef);
  local @CONNECTS;

  my $error = connect_through($storage, $view);

  ok defined $error, 'a view over a DB2-form answer: the storage refuses the connection';
  like $error // '', qr/'HOSTNAME'/, '... naming the form';
  unlike $error // '', qr/master\.example|k270-/, '... quoting neither the DSN nor a credential';
  is scalar @CONNECTS, 0, "... and DBI->connect is never called with the answer's server";
}

# ---------------------------------------------------------------------------
# 4. An answer with no DSN text to rewrite.
# ---------------------------------------------------------------------------
{
  my $made = 0;
  my $view = view_over([ sub { $made++; T::Handle->new } ]);
  my $storage = DBIO::Storage::DBI->new(undef);
  local @CONNECTS;

  my $error = connect_through($storage, $view);

  ok defined $error, 'a view over a coderef answer is refused: its host cannot be bound';
  like $error // '', qr/a code reference in place of a DSN/, '... naming the form';
  is $made, 0, '... before the coderef is called';
}

{
  my $made = 0;
  my $view = view_over({ dbh_maker => sub { $made++; T::Handle->new } });
  my $storage = DBIO::Storage::DBI->new(undef);

  my $error = connect_through($storage, $view);

  ok defined $error, 'a view over a dbh_maker answer is refused: its host cannot be bound';
  like $error // '', qr/dbh_maker: code opens the connection/, '... naming the form';
  is $made, 0, '... before the dbh_maker is called';
}

{
  my $view = view_over({ dsn => 'dbi:Pg:dbname=app;host=master.example', user => 'k270-user', password => 'k270-pw' });
  my $storage = DBIO::Storage::DBI->new(undef);
  local @CONNECTS;

  my $error = connect_through($storage, $view);

  ok !defined $error, 'a view over a hash answer carrying a dsn: the storage connects' or diag $error;
  is $CONNECTS[0][0], 'dbi:Pg:port=6000;dbname=app;host=replica.example',
    "... with the view's host and port bound into the DSN";
  ok !grep({ exists $_->[3]{host} || exists $_->[3]{port} } grep { ref $_->[3] eq 'HASH' } @CONNECTS),
    '... and no host or port reaches DBI->connect as an attribute';
  is_deeply [ @{ $CONNECTS[0] }[1, 2] ], [ 'k270-user', 'k270-pw' ],
    '... with the credentials of the answer';
}

{
  # unchanged: no DSN at all (DBI_DSN), and an empty hash (k253)
  my $undef = view_over([ undef, 'u', 'p' ])->connect_info_for;
  ok !defined $undef->[0], 'an undef DSN is handed on as it came';
  my $empty = view_over({})->connect_info_for;
  is_deeply $empty, {}, 'an empty hash is handed on as it came (karr k253)';
}

# ---------------------------------------------------------------------------
# 5. A host that would split a DSN.
# ---------------------------------------------------------------------------
{
  # control: connection parameters go through the storage's DSN seam, which
  # refuses the value (15-connect-params-dsn-seam.t claims that for a static
  # hash; here it arrives through a view)
  my $view = view_over({ dbname => 'app', user => 'k270-user', password => 'k270-pw' }, 'evil.example;dbname=other');
  my $storage = T::FakeDriver::Storage->new(undef);
  local @CONNECTS;

  throws_ok { $storage->connect_info([ $view ]) }
    qr/Cannot build a DSN from the connection parameter 'host': its value contains ';'/,
    "a view's host containing ';' over connection parameters: the storage refuses it (control)";
  unlike "$@", qr/k270-/, '... quoting no credential';
  is scalar @CONNECTS, 0, '... and nothing is connected';
}

{
  @T::Seam::Storage::ASKED = ();
  my ($got, $error) = bound_dsn('dbi:FakeSeam:server=MASTER', 'evil.example;dbname=other', 'T::Seam::Storage');
  ok !defined $got, "a view's host containing ';' over a DSN is refused";
  like $error // '', qr/host\/port containing ';'/, '... naming the form';
  unlike $error // '', qr/evil\.example|MASTER/, '... quoting neither host nor DSN';
  is scalar @T::Seam::Storage::ASKED, 0, '... before the driver seam is asked';

  ($got, $error) = bound_dsn('dbi:Pg:dbname=app', { host => 'ok.example', port => '1;2' });
  like $error // '', qr/host\/port containing ';'/, "a port containing ';' is refused the same way";
}

# ---------------------------------------------------------------------------
# 6. The driver seam.
# ---------------------------------------------------------------------------
{
  # the core default, called as a class method
  my @r = DBIO::Storage::DBI->_bind_host_into_dsn('Pg', 'dbi:Pg:dbname=a;host=m', 'h', 5);
  is_deeply \@r, [ 'dbi:Pg:port=5;dbname=a;host=h' ], 'the default seam answers the bound DSN, as a class method';
  @r = DBIO::Storage::DBI->_bind_host_into_dsn('Sybase', 'dbi:Sybase:server=M', 'h', undef);
  is_deeply \@r, [ undef, "the key 'server' naming the server" ], 'the default seam declines with (undef, $form)';
}

{
  # through the storage's class
  my $storage = T::Seam::Storage->new(undef);
  local @CONNECTS;
  @T::Seam::Storage::ASKED = ();
  my $view = view_over([ 'dbi:FakeSeam:server=MASTER;db=x', 'u', 'p', {} ]);

  my $error = connect_through($storage, $view);

  ok !defined $error, 'a driver storage overriding the seam: the view connects' or diag $error;
  is $CONNECTS[0][0], 'dbi:FakeSeam:server=replica.example,6000;db=x',
    "... DBI->connect sees the DSN the driver bound";
  is_deeply $T::Seam::Storage::ASKED[0], [ 'FakeSeam', 'dbi:FakeSeam:server=MASTER;db=x', 'replica.example', 6000 ],
    '... the driver was asked with its DBD name, the DSN, host and port';
}

{
  # through the registry: the storage is still the generic class
  my $storage = DBIO::Storage::DBI->new(undef);
  local @CONNECTS;
  my $view = view_over([ 'dbi:FakeSeam:server=MASTER', 'u', 'p', {} ]);

  my $error = connect_through($storage, $view);

  ok !defined $error, 'a generic storage: the registry names the driver whose seam is asked' or diag $error;
  is $CONNECTS[0][0], 'dbi:FakeSeam:server=replica.example,6000', '... and its binding is what connects';
}

{
  # a driver declining
  my $view = view_over([ 'dbi:FakeNo:whatever', 'k270-user', 'k270-pw', {} ]);
  my $storage = DBIO::Storage::DBI->new(undef);
  local @CONNECTS;

  my $error = connect_through($storage, $view);

  ok defined $error, 'a driver whose seam declines: the view is refused';
  like $error // '', qr/form X/, '... naming the form the driver gave';
  unlike $error // '', qr/whatever|k270-/, '... quoting neither the DSN nor a credential';
  is scalar @CONNECTS, 0, '... and nothing is connected';
}

{
  # a registered driver that does not override: the core default stands
  my ($got) = bound_dsn('dbi:FakeHB:dbname=a;host=m');
  is $got, 'dbi:FakeHB:port=6000;dbname=a;host=replica.example',
    'a registered driver without a seam of its own gets the core default';
}

{
  # the storage's own class wins over the registry entry of the DSN's DBD
  my $storage = T::Seam::Storage->new(undef);
  my ($got) = bound_dsn('dbi:FakeNo:server=MASTER', undef, $storage);
  is $got, 'dbi:FakeNo:server=replica.example,6000', "the storage class's seam comes before the registry's";
}

done_testing;
