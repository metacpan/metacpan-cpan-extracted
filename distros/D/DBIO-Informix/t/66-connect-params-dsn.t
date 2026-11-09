use strict;
use warnings;

use Test::More;
use Test::Exception;

use DBI;
use DBIO::Optional::Dependencies ();
use DBIO::Schema;
use DBIO::Storage::DBI;
use DBIO::Informix::Storage;
use DBIO::AccessBroker;
use DBIO::AccessBroker::Static;

# OFFLINE half plus a live half (karr k23; core ADR 0057 and ADR 0013 addendum).
#
# Connection parameters without a DSN -- { dbname, host, port }, as
# DBIO::AccessBroker::Static answers them -- become a DSN through the
# storage's seam _connect_params_dsn, and a DBIO::AccessBroker::HostBound view
# puts its host into a DSN through _bind_host_into_dsn. Core's default form is
#
#   dbi:<DBD>:dbname=..;host=..;port=..
#
# and DBD::Informix takes none of it (measured against Informix 15.0.1, the
# live block below repeats it): "dbi:Informix:database=x" and
# "dbi:Informix:dbname=x;server=y" are both SQL -354 "Incorrect database or
# cursor name format". The one form is
#
#   dbi:Informix:database[@server]
#
# where the part after the @ is a DBSERVERNAME of the sqlhosts file -- not a
# host name and not host:port. "database@dbio.dev.cihq" (a host name) and
# "database@server:9088" are both SQL -25555 "Server ... is not listed as a
# dbserver name in sqlhosts". The port belongs to the sqlhosts entry and the
# DSN has no place for it. So:
#
#   1. dbname alone is dbi:Informix:<dbname> (the INFORMIXSERVER of the
#      environment decides the server);
#   2. host is the server name: dbi:Informix:<dbname>@<host>;
#   3. port refuses, naming sqlhosts: dropping it would connect somewhere the
#      caller did not ask for;
#   4. no dbname refuses (a connection to no database is no DBIO storage);
#   5. a HostBound view replaces the server of dbi:Informix:db[@server] and
#      adds it when the DSN has none; a view carrying a port declines, and so
#      does every DSN not of that form;
#   6. all of it through the real connect path, so dbname, host and port do
#      not reach DBI->connect as attributes.

{
  package T::Informix::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('Informix');
}

{
  package T::FakeDBH;
  sub new { bless { Active => 1, AutoCommit => 1, RaiseError => 1 }, shift }
  sub FETCH { $_[0]{$_[1]} }
}

sub broker {
  return DBIO::AccessBroker::Static->new(username => 'u', password => 'pw', @_);
}

sub storage_for { T::Informix::Schema->connect(@_)->storage }

isnt (
  DBIO::Informix::Storage->can('_connect_params_dsn'),
  DBIO::Storage::DBI->can('_connect_params_dsn'),
  'DBIO::Informix::Storage has a _connect_params_dsn of its own: core\'s '
. 'default form is one DBD::Informix does not take',
);

isnt (
  DBIO::Informix::Storage->can('_bind_host_into_dsn'),
  DBIO::Storage::DBI->can('_bind_host_into_dsn'),
  '... and a _bind_host_into_dsn of its own',
);

# --------------------------------------------- 1, 2, 6: through the real path

{
  my $storage = storage_for(broker(dbname => 'myapp'));
  is ref $storage, 'DBIO::Informix::Storage', 'the schema declares the Informix storage';
  is $storage->_dbi_connect_info->[0], 'dbi:Informix:myapp',
    'dbname alone is dbi:Informix:<database>';
  is_deeply [ @{ $storage->_dbi_connect_info }[1, 2] ], [ 'u', 'pw' ],
    '... user and password stay DBI->connect arguments';
  ok !exists $storage->_dbi_connect_info->[3]{dbname},
    '... and dbname is no DBI attribute';
}

{
  my $broker  = broker(dbname => 'myapp', host => 'ifxprod');
  my $storage = storage_for($broker);

  is $storage->_dbi_connect_info->[0], 'dbi:Informix:myapp@ifxprod',
    'dbname and host are dbi:Informix:<database>@<server>: the host is the '
  . 'DBSERVERNAME';

  $broker->host('ifxstandby');
  my @connects;
  {
    no warnings qw(redefine once);
    local *DBI::connect = sub { shift; push @connects, [@_]; T::FakeDBH->new };
    $storage->_connect;
  }
  is $connects[0][0], 'dbi:Informix:myapp@ifxstandby',
    '... built again from what the broker answers at connect time';
  ok !exists $connects[0][3]{host} && !exists $connects[0][3]{dbname},
    '... with none of the parts left over as attributes';
}

is storage_for({ dbname => 'myapp', host => 'ifxprod', user => 'u', password => 'pw' })
     ->_dbi_connect_info->[0],
  'dbi:Informix:myapp@ifxprod',
  'a connect-info hash without a dsn takes the same path as a broker';

# ------------------------------------------------------------ 3, 4: refusals

throws_ok {
  storage_for(broker(dbname => 'myapp', host => 'ifxprod', port => 9088));
} qr/DBD::Informix DSN.*port/s,
  'a port refuses: the DSN has no place for one';
like "$@", qr/sqlhosts/, '... naming sqlhosts, where the port lives';

throws_ok {
  storage_for(broker(dbname => 'myapp', port => 9088));
} qr/DBD::Informix DSN.*port/s, 'a port without a host refuses as well';

throws_ok {
  storage_for(broker(host => 'ifxprod'));
} qr/DBD::Informix DSN.*without a dbname/s,
  'host without a dbname refuses: there is no default database';

# ------------------------------------------ 5: the HostBound view's seam

{
  package T::Broker;
  use base 'DBIO::AccessBroker';
  sub new { bless { answer => $_[1] }, $_[0] }
  sub connect_info_for { $_[0]{answer} }
}

sub bound_dsn {
  my ($dsn, $host) = @_;
  my $view = T::Broker->new([ $dsn, 'u', 'pw', {} ])
    ->for_host($host || { host => 'ifxstandby' });
  my $info;
  return (undef, "$@")
    unless eval { $info = $view->connect_info_for_storage(DBIO::Informix::Storage->new(undef)); 1 };
  return ($info->[0], undef);
}

for my $case (
  [ 'database and server',      'dbi:Informix:myapp@ifxprod',   'dbi:Informix:myapp@ifxstandby' ],
  [ 'database only: the server is added', 'dbi:Informix:myapp',  'dbi:Informix:myapp@ifxstandby' ],
  [ 'server only, no database', 'dbi:Informix:@ifxprod',        'dbi:Informix:@ifxstandby' ],
  [ 'upper-case prefix',        'DBI:Informix:myapp@ifxprod',   'DBI:Informix:myapp@ifxstandby' ],
  [ 'driver attributes',        'dbi:Informix(RaiseError=1):myapp@ifxprod',
                                'dbi:Informix(RaiseError=1):myapp@ifxstandby' ],
) {
  my ($label, $dsn, $expected) = @$case;
  my ($got, $error) = bound_dsn($dsn);
  is $got, $expected, "bound: $label" or diag $error;
  unlike $got // '', qr/ifxprod/, '... the answer\'s server is gone';
}

for my $case (
  [ 'a view with a port',
    'dbi:Informix:myapp@ifxprod', { host => 'ifxstandby', port => 9088 }, qr/port/ ],
  [ 'the key form core\'s default writes',
    'dbi:Informix:dbname=myapp;host=ifxprod', undef, qr/dbi:Informix:database/ ],
  [ 'a DSN without a driver prefix',
    'myapp@ifxprod', undef, qr/dbi:Informix:database/ ],
) {
  my ($label, $dsn, $host, $form) = @$case;
  my ($got, $error) = bound_dsn($dsn, $host);
  is $got, undef, "declined: $label";
  like $error // '', $form, '... naming the form';
  unlike $error // '', qr/ifxprod|myapp|ifxstandby|pw/,
    '... and neither a value of the DSN nor a credential';
}

# ------------------------------------------------------------------- live

SKIP: {
  my ($dsn, $user, $pass) = @ENV{map { "DBIO_TEST_INFORMIX_$_" } qw/DSN USER PASS/};

  skip 'Set $ENV{DBIO_TEST_INFORMIX_DSN}, _USER and _PASS to run the live half', 5
    unless $dsn;

  skip 'Test needs ' . DBIO::Optional::Dependencies->req_missing_for('test_rdbms_informix'), 5
    unless DBIO::Optional::Dependencies->req_ok_for('test_rdbms_informix');

  my ($db, $server) = $dsn =~ /\Adbi:Informix:([^@;=]+)\@([^;=]+)\z/i
    or skip "The live DSN $dsn is not dbi:Informix:database\@server", 5;

  my $connects = sub {
    my $schema = T::Informix::Schema->connect(@_);
    my $ok = eval { $schema->storage->dbh; 1 };
    return $ok ? 'connected' : "$@";
  };

  is $connects->(broker(username => $user, password => $pass, dbname => $db, host => $server)),
    'connected',
    'live: the server accepts dbi:Informix:<database>@<server> built from a broker';

  like $connects->(broker(username => $user, password => $pass, dbname => $db, host => 'no_such_server')),
    qr/-25555/,
    'live: a host that is no DBSERVERNAME fails loudly, with the sqlhosts '
  . 'error, rather than connecting somewhere else';

  my $default = DBIO::Storage::DBI::_connect_params_dsn(
    DBIO::Informix::Storage->new(undef), 'Informix', { dbname => $db, host => $server });
  my $dbh = DBI->connect($default, $user, $pass, { PrintError => 0, RaiseError => 0 });
  ok !$dbh, 'live: core\'s default form is refused by the server ...';
  like +(DBI->errstr // ''), qr/-354/, '... with -354, incorrect database name format';

  my $bound = DBIO::Informix::Storage->_bind_host_into_dsn('Informix', "dbi:Informix:$db", $server, undef);
  is $bound, "dbi:Informix:$db\@$server", 'live: the bound DSN is the live DSN';
}

done_testing;
