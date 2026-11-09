use strict;
use warnings;
use Test::More;
use DBI;
use DBIO::AccessBroker;
use DBIO::PostgreSQL::Storage;

# OFFLINE test: the driver seam _bind_host_into_dsn, which a HostBound view
# (a Replicated replicant, karr k270/k276 in core) asks to put its host into
# the DSN of a broker's answer (karr k126).
#
# WHY: libpq lets hostaddr= win over host=. Core's default seam declines a
# DSN with hostaddr= -- right for a driver that does not know the key, but
# for PostgreSQL a refusal of something it can do: take hostaddr= out, and
# host= is what libpq connects to. Other places libpq reads a host from
# cannot be taken out of a DSN, and are refused by name.
#
# What this file claims:
#   1. a hostaddr= token, whatever its case and however often it stands, is
#      removed; the view's host (and port) are bound as core binds them, so
#      an IP host connects without DNS and a name host is resolved;
#   2. a DSN without hostaddr= is bound exactly as core binds it;
#   3. service= is refused (a service file may name hostaddr), and so is a
#      dbname that is a conninfo (postgresql://..., postgres://..., or with
#      '=') -- naming the form, never a value of the DSN;
#   4. a port list in the DSN is refused where the view has no port to
#      replace it, and replaced where it has;
#   5. host=a,b is replaced by the one host of the view;
#   6. through a view and a storage, DBI->connect sees the bound DSN, and
#      sees none for a refused form.
#
# THE SUBSTITUTIONS: DBI->connect records its arguments; no database.

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

sub seam { DBIO::PostgreSQL::Storage->_bind_host_into_dsn('Pg', @_[0 .. 2]) }

# What core binds: the reference every untouched DSN is compared with.
sub core { DBIO::Storage::DBI->_bind_host_into_dsn('Pg', @_[0 .. 2]) }

# ---------------------------------------------------------------------------
# 1. hostaddr= is removed, host= and port= bound.
# ---------------------------------------------------------------------------
for my $case (
  [ 'an IP host',
    'dbi:Pg:dbname=app;host=master.example;hostaddr=10.0.0.1;port=5432', '10.0.0.7', 6000,
    'dbi:Pg:dbname=app;host=10.0.0.7;port=6000' ],
  [ 'a host name',
    'dbi:Pg:dbname=app;hostaddr=10.0.0.1;host=master.example', 'replica.example', 6000,
    'dbi:Pg:port=6000;dbname=app;host=replica.example' ],
  [ 'upper-case key',
    'dbi:Pg:dbname=app;HOSTADDR=10.0.0.1;host=master.example', 'replica.example', 6000,
    'dbi:Pg:port=6000;dbname=app;host=replica.example' ],
  [ 'mixed-case key, no host= in the DSN',
    'dbi:Pg:dbname=app;HostAddr=10.0.0.1', 'replica.example', 6000,
    'dbi:Pg:port=6000;host=replica.example;dbname=app' ],
  [ 'several tokens',
    'dbi:Pg:hostaddr=10.0.0.1;dbname=app;hostaddr=10.0.0.2;host=m;HOSTADDR=10.0.0.3', 'replica.example', undef,
    'dbi:Pg:dbname=app;host=replica.example' ],
  [ 'the only token',
    'dbi:Pg:hostaddr=10.0.0.1', 'replica.example', 6000,
    'dbi:Pg:port=6000;host=replica.example' ],
  [ 'driver attributes in the prefix',
    'dbi:Pg(RaiseError=1):dbname=app;hostaddr=10.0.0.1;host=m', 'replica.example', undef,
    'dbi:Pg(RaiseError=1):dbname=app;host=replica.example' ],
) {
  my ($label, $dsn, $host, $port, $expected) = @$case;
  my @got = seam($dsn, $host, $port);
  is $got[0], $expected, "$label: hostaddr= is gone, the view's host is bound";
  is scalar(@got), 1, '... and nothing declines';
  unlike $got[0] // '', qr/hostaddr/i, '... no hostaddr token is left';
}

# ---------------------------------------------------------------------------
# 2. A DSN without hostaddr= is bound as core binds it.
# ---------------------------------------------------------------------------
for my $dsn (
  'dbi:Pg:dbname=app;host=master.example;port=5432',
  'dbi:Pg:dbname=app',
  'dbi:Pg:dbname=app;sslmode=require;host=m',
  'dbi:Pg:',
  'DBI:Pg:dbname=app;HOST=m',
  q{dbi:Pg:dbname='my db';host=m},
) {
  is_deeply [ seam($dsn, 'replica.example', 6000) ], [ core($dsn, 'replica.example', 6000) ],
    "$dsn: as core binds it";
}

# ---------------------------------------------------------------------------
# 3. service= and a conninfo dbname are refused, naming the form.
# ---------------------------------------------------------------------------
for my $case (
  [ 'service=',              'dbi:Pg:service=prod;dbname=app',                           qr/'service'/,  qr/prod/ ],
  [ 'SERVICE=',              'dbi:Pg:dbname=app;SERVICE=prod',                           qr/'SERVICE'/,  qr/prod/ ],
  [ 'dbname=postgresql://',  'dbi:Pg:dbname=postgresql://u:s3cret@master.example/app',   qr/'dbname'/,  qr/master\.example|s3cret/ ],
  [ 'dbname=postgres://',    'dbi:Pg:dbname=postgres://master.example/app',              qr/'dbname'/,  qr/master\.example/ ],
  [ 'db=postgresql://',      'dbi:Pg:db=postgresql://master.example/app',                qr/'db'/,      qr/master\.example/ ],
  [ 'database=postgres://',  'dbi:Pg:database=postgres://master.example/app',            qr/'database'/, qr/master\.example/ ],
  [ 'dbname with =',         'dbi:Pg:dbname=app host=master.example',                    qr/'dbname'/,  qr/master\.example/ ],
  [ 'service with hostaddr', 'dbi:Pg:service=prod;hostaddr=10.0.0.1',                    qr/'service'/, qr/prod|10\.0\.0\.1/ ],
) {
  my ($label, $dsn, $form, $leak) = @$case;
  my @got = seam($dsn, 'replica.example', 6000);
  ok !defined $got[0], "$label: no DSN is handed on";
  like $got[1] // '', $form, '... the refusal names the form';
  unlike $got[1] // '', $leak, '... and quotes no value of the DSN';
}

{
  my @got = seam('dbi:Pg:service=prod', 'replica.example', 6000);
  like $got[1] // '', qr/service file may name hostaddr/, 'service=: the reason is the service file';
}

# ---------------------------------------------------------------------------
# 4. A port list.
# ---------------------------------------------------------------------------
{
  my @got = seam('dbi:Pg:dbname=app;host=a,b;port=5432,5433', 'replica.example', undef);
  ok !defined $got[0], 'a port list and no port in the view: refused';
  like $got[1] // '', qr/a port list without a port in the view/, '... naming the form';
  unlike $got[1] // '', qr/5433|replica\.example/, '... without a value';

  is_deeply [ seam('dbi:Pg:dbname=app;host=a,b;port=5432,5433', 'replica.example', 6000) ],
    [ 'dbi:Pg:dbname=app;host=replica.example;port=6000' ],
    'a port list with a port in the view: the whole token is replaced';

  is_deeply [ seam('dbi:Pg:dbname=app;host=a;port=5432', 'replica.example', undef) ],
    [ 'dbi:Pg:dbname=app;host=replica.example;port=5432' ],
    'a single port and none in the view: left as the answer has it';
}

# ---------------------------------------------------------------------------
# 5. host=a,b
# ---------------------------------------------------------------------------
is_deeply [ seam('dbi:Pg:dbname=app;host=a.example,b.example;port=5432', 'replica.example', 6000) ],
  [ 'dbi:Pg:dbname=app;host=replica.example;port=6000' ],
  'host=a,b: replaced by the one host of the view';

# ---------------------------------------------------------------------------
# 6. Through a view and a storage.
# ---------------------------------------------------------------------------
sub view_over {
  my ($answer, $host, $port) = @_;
  return T::Broker->new($answer)->for_host({ host => $host, (defined $port ? (port => $port) : ()) });
}

sub connect_through {
  my ($storage, $view) = @_;
  return eval { $storage->connect_info([ $view ]); $storage->_connect; 1 } ? undef : "$@";
}

{
  my $info = view_over(
    [ 'dbi:Pg:dbname=app;hostaddr=10.0.0.1;host=master.example', 'u', 'p', {} ], 'replica.example', 6000
  )->connect_info_for_storage(DBIO::PostgreSQL::Storage->new(undef));
  is $info->[0], 'dbi:Pg:port=6000;dbname=app;host=replica.example',
    'a view asked with a PostgreSQL storage: the DSN is bound, hostaddr gone';
  is_deeply [ @$info[1, 2] ], [ 'u', 'p' ], '... credentials as they came';
}

{
  # the storage is still the generic class before its first connection:
  # the registry finds the driver by the DBD named in the DSN
  my $info = view_over(
    [ 'dbi:Pg:dbname=app;hostaddr=10.0.0.1', 'u', 'p', {} ], 'replica.example'
  )->connect_info_for_storage(DBIO::Storage::DBI->new(undef));
  is $info->[0], 'dbi:Pg:host=replica.example;dbname=app',
    'a generic storage: the driver registered for Pg answers';
}

{
  local @CONNECTS;
  my $storage = DBIO::PostgreSQL::Storage->new(undef);
  my $error = connect_through($storage,
    view_over([ 'dbi:Pg:dbname=app;hostaddr=10.0.0.1;host=master.example', 'u', 'p', {} ], 'replica.example', 6000));
  is $error, undef, 'a hostaddr= answer through a view connects';
  is scalar @CONNECTS, 1, '... once';
  like $CONNECTS[0][0] // '', qr/^dbi:Pg:.*host=replica\.example/, "... to the view's host";
  unlike $CONNECTS[0][0] // '', qr/hostaddr|10\.0\.0\.1|master\.example/i, "... and the answer's server is not in the DSN";
}

{
  local @CONNECTS;
  my $storage = DBIO::PostgreSQL::Storage->new(undef);
  my $error = connect_through($storage,
    view_over([ 'dbi:Pg:service=prod;host=master.example', 'k126-user', 'k126-pw', {} ], 'replica.example', 6000));
  ok defined $error, 'a service= answer through a view is refused';
  like $error // '', qr/'service'/, '... naming the form';
  unlike $error // '', qr/master\.example|prod|k126-/, '... quoting neither the DSN nor a credential';
  is scalar @CONNECTS, 0, '... and DBI->connect is never called';
}

done_testing;
