# ABSTRACT: host and port without a dsn or a dbname key are refused
use strict;
use warnings;

use Test::More;
use Test::Exception;

use DBI;
use DBIO::Storage::DBI;
use DBIO::AccessBroker;
use DBIO::AccessBroker::Static;

# OFFLINE (karr k267, found at dbio-db2 k37; ADR 0057 and its addendum
# 2026-10-06). A hash of connection parameters without a dsn is turned into a
# DSN by the driver storage's seam, _connect_params_dsn -- asked when the hash
# has a dbname KEY. A hash with host and/or port and neither a dsn nor a
# dbname key names a server and no database: there is no DSN to build them
# into. WHY it is refused rather than passed on: as DBI attributes host and
# port bind nothing, and the connection would go wherever $ENV{DBI_DSN}
# points -- with the user and password given for the host named.
#
# What this file claims:
#   1. the dbname KEY decides, not its value: with the key, even undef (as
#      DBIO::AccessBroker::Static answers a dbname not given), the seam is
#      asked with the parts that have a value and host/port are no DBI
#      attributes (control -- ADR 0057);
#   2. without a dsn and without the dbname key, host and/or port in static
#      connect info are refused at connect_info: the error names the keys
#      given and what is missing, never a value; the seam is not asked,
#      nothing is stored to connect from, and nothing of the hash reaches
#      DBI->connect afterwards -- with $ENV{DBI_DSN} set or not, on the
#      generic storage or a driver's;
#   3. the same hash as a broker's answer is refused naming the broker class,
#      at connect_info and at a connection after it, and DBI->connect is not
#      called;
#   4. beside a dsn, host and port are DBI attributes as before (control);
#      and static connect info without host and port -- user and password
#      alone -- is refused as well, with $ENV{DBI_DSN} set or not: connect
#      info without a DSN (karr k306, pinned in full by
#      37-static-without-dsn-refused.t).
#
# THE SUBSTITUTIONS: a fake driver storage registered for the DBD name
# 'K267Fake' whose seam records what it is asked; DBI->connect records its
# arguments; no database is involved. The port is a marker, not a number: a
# number may turn up in the path an error message ends with.

delete @ENV{qw( DBI_DSN DBI_DRIVER )};

{
  package T::Driver::Storage;
  use base 'DBIO::Storage::DBI';
  DBIO::Storage::DBI->register_driver(K267Fake => __PACKAGE__);

  our @ASKED;
  sub _connect_params_dsn {
    my ($self, $driver, $params) = @_;
    push @ASKED, { %$params };
    return $self->next::method($driver, $params);
  }
}

{
  package T::HashBroker;
  use base 'DBIO::AccessBroker';
  sub new { my ($class, %answer) = @_; bless { answer => \%answer }, $class }
  sub connect_info_for { +{ %{ $_[0]{answer} } } }
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

my $ENV_DSN = 'dbi:K267Fake:from-the-environment';
my %HOST_PORT = (
  host => 'k267-host.example', port => 'k267-port', user => 'k267-user', password => 'k267-secret',
);
my $VALUE = qr/k267-(?:host|port|user|secret)/;   # every value of %HOST_PORT

# connect_info plus one connection; what was asked of the seam, what DBI->connect got
sub connect_with {
  my ($connect_info) = @_;
  local @T::Driver::Storage::ASKED;
  local @CONNECTS;
  my $storage = T::Driver::Storage->new(undef);
  my $lived = eval { $storage->connect_info($connect_info); $storage->_connect; 1 };
  return {
    lived   => $lived,
    error   => "$@",
    asked   => [ @T::Driver::Storage::ASKED ],
    connect => $CONNECTS[-1],
    stored  => $storage->{_dbi_connect_info},
  };
}

# ---------------------------------------------------------------------------
# 1. With the dbname key: connection parameters (control).
# ---------------------------------------------------------------------------
my %PARTS    = map { $_ => $HOST_PORT{$_} } qw( host port );
my $PARTS_DSN = "host=$HOST_PORT{host};port=$HOST_PORT{port}";

for my $case (
  [ 'static connect info, dbname given' => [ { %HOST_PORT, dbname => 'app' } ],
    { dbname => 'app', %PARTS },
    "dbi:K267Fake:dbname=app;$PARTS_DSN" ],
  [ 'static connect info, dbname key with undef' => [ { %HOST_PORT, dbname => undef } ],
    { %PARTS },
    "dbi:K267Fake:$PARTS_DSN" ],
  [ 'a Static broker without a dbname' => [ DBIO::AccessBroker::Static->new(
      %PARTS, username => $HOST_PORT{user}, password => $HOST_PORT{password},
    ) ],
    { %PARTS },
    "dbi:K267Fake:$PARTS_DSN" ],
) {
  my ($name, $connect_info, $parts, $dsn) = @$case;
  my $got = connect_with($connect_info);

  ok $got->{lived}, "$name: a connection is opened" or diag $got->{error};
  is_deeply $got->{asked}[-1], $parts, "$name: the seam is asked, with the parts that have a value";
  is_deeply [ @{ $got->{connect} }[0 .. 2] ], [ $dsn, @HOST_PORT{qw( user password )} ],
    "$name: DBI->connect gets the DSN the seam built";
  my @as_attributes = grep { exists $got->{connect}[3]{$_} } qw( host port dbname );
  is_deeply \@as_attributes, [], "$name: host, port and dbname are no DBI attributes";
}

# ---------------------------------------------------------------------------
# 2 + 3. Without a dsn and without the dbname key: refused.
# ---------------------------------------------------------------------------
my %GIVEN = (
  'host and port' => [ qw( host port ) ],
  'host alone'    => [ 'host' ],
  'port alone'    => [ 'port' ],
);

for my $class ('DBIO::Storage::DBI', 'T::Driver::Storage') {
  for my $given (sort keys %GIVEN) {
    my @parts = @{ $GIVEN{$given} };
    my %hash  = map { $_ => $HOST_PORT{$_} } @parts, qw( user password );

    my $static = join ' and ', map { "'$_'" } @parts;
    my $shape  = 'a hash with ' . join(' and ', @parts) . ', but neither a dsn nor a dbname key';

    for my $env_dsn (undef, $ENV_DSN) {
      local %ENV = (%ENV, defined $env_dsn ? (DBI_DSN => $env_dsn) : ());
      my $t = "$class, $given, without a dsn or a dbname key, "
            . (defined $env_dsn ? 'DBI_DSN set' : 'no DBI_DSN');

      {
        local @T::Driver::Storage::ASKED;
        local @CONNECTS;
        my $storage = $class->new(undef);

        throws_ok { $storage->connect_info([ { %hash } ]) }
          qr/Connect info gives \Q$static\E but neither a dsn nor a dbname/,
          "static connect info, $t: refused at connect_info, naming what is given and what is missing";
        unlike "$@", $VALUE, "static connect info, $t: naming no value";
        is_deeply \@T::Driver::Storage::ASKED, [], "static connect info, $t: the seam is not asked";
        is $storage->{_dbi_connect_info}, undef,
          "static connect info, $t: nothing is stored to connect from -- host and port are no DBI attributes";

        # whatever a connection on this storage does now, it does without the hash
        eval { $storage->_connect };
        my @of_the_hash = grep { defined && /$VALUE/ }
          map { ref $_ eq 'HASH' ? %$_ : $_ } map { @$_ } @CONNECTS;
        is_deeply \@of_the_hash, [],
          "static connect info, $t: nothing of the hash reaches DBI->connect afterwards";
      }

      {
        local @T::Driver::Storage::ASKED;
        local @CONNECTS;
        my $storage = $class->new(undef);
        my $refused = qr/AccessBroker T::HashBroker answered connect info without a DSN \(\Q$shape\E\)/;

        throws_ok { $storage->connect_info([ T::HashBroker->new(%hash) ]) } $refused,
          "a broker answer, $t: refused at connect_info, naming the broker class and the shape";
        unlike "$@", $VALUE, "a broker answer, $t: naming no value";
        throws_ok { $storage->_connect } $refused,
          "a broker answer, $t: a connection after it is refused the same";
        is_deeply \@T::Driver::Storage::ASKED, [], "a broker answer, $t: the seam is not asked";
        is scalar @CONNECTS, 0, "a broker answer, $t: DBI->connect is not called";
        is $storage->{_dbi_connect_info}, undef,
          "a broker answer, $t: nothing is stored to connect from -- host and port are no DBI attributes";
      }
    }
  }
}

# ---------------------------------------------------------------------------
# 4. Beside a dsn (control); and without host and port.
# ---------------------------------------------------------------------------
{
  my $got = connect_with([ { %HOST_PORT, dsn => 'dbi:K267Fake:given' } ]);

  ok $got->{lived}, 'host and port beside a dsn: a connection is opened' or diag $got->{error};
  is_deeply $got->{asked}, [], 'host and port beside a dsn: the seam is not asked';
  is_deeply [ @{ $got->{connect} }[0 .. 2] ], [ 'dbi:K267Fake:given', @HOST_PORT{qw( user password )} ],
    'host and port beside a dsn: DBI->connect gets the dsn given';
  is_deeply { map { $_ => $got->{connect}[3]{$_} } qw( host port ) }, { %PARTS },
    'host and port beside a dsn: they are DBI attributes';
}

{
  my %credentials = map { $_ => $HOST_PORT{$_} } qw( user password );

  for my $env_dsn (undef, $ENV_DSN) {
    local %ENV = (%ENV, defined $env_dsn ? (DBI_DSN => $env_dsn) : ());
    my $t = 'static user and password alone, ' . (defined $env_dsn ? 'DBI_DSN set' : 'no DBI_DSN');

    my $got = connect_with([ { %credentials } ]);
    ok !$got->{lived}, "$t: no connection is opened";
    like $got->{error}, qr/Connect info without a DSN \(a hash with neither a dsn nor a dbname key\)/,
      "$t: ... refused for want of a DSN";
    is $got->{connect}, undef, "$t: ... and DBI->connect is not called";
  }
}

done_testing;
