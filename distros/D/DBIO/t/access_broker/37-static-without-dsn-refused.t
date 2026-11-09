# ABSTRACT: static connect info without a DSN is refused, whatever $ENV{DBI_DSN} says
use strict;
use warnings;

use Test::More;
use Test::Exception;

use DBI;
use DBIO::Schema;
use DBIO::Storage::DBI;
use DBIO::AccessBroker;

# OFFLINE (karr k306; maintainer's decision 2026-10-12, points (b) and (d)).
#
# WHY: the DSN decides the driver. Connect info that names none leaves the
# choice of the database -- and of the DBD -- to $ENV{DBI_DSN}: the user and
# password given in the call go to whatever server the environment of the
# process happens to name. So a static connect info has to carry its DSN, and
# the environment is no substitute for it.
#
# What this file claims:
#   1. Static connect info without a DSN is refused at connect_info: no
#      arguments at all, the DBI form with an undefined or an empty DSN, a hash
#      whose dsn is undefined or empty (with host, port and user beside it, the
#      measuring point of the card, or without), a hash with neither a dsn nor
#      a dbname key. The error names the shape, never a value. It is the same
#      with $ENV{DBI_DSN} set, on the generic storage and on a driver's, and
#      through Schema->connect.
#   2. After the refusal the storage has nothing to connect from: a connection
#      on it does not reach DBI->connect, with $ENV{DBI_DSN} set or not. A
#      storage that never got connect info is in the same state.
#   3. The forms that are not meant to carry a static DSN are not judged
#      (control): a code reference, a dbh_maker in a hash, and an AccessBroker
#      -- answering a DSN or a dbh_maker -- configure the storage and connect,
#      with $ENV{DBI_DSN} set or not, and never to the DSN of the environment.
#      A broker whose answer has no DSN keeps its own refusal, naming the
#      broker class.
#   4. A hash that names the database by its parts (a dbname key) has a DSN:
#      the driver's storage builds it (ADR 0057). Not refused (control).
#
# THE SUBSTITUTIONS: DBI->connect is replaced by a recorder returning a stand-in
# handle; a fake driver storage registered for the DBD name 'K306Fake'; no
# database is involved.

delete @ENV{qw( DBI_DSN DBI_DRIVER )};

{
  package T::Driver::Storage;
  use base 'DBIO::Storage::DBI';
  DBIO::Storage::DBI->register_driver(K306Fake => __PACKAGE__);
}

{
  package T::Schema;
  use base 'DBIO::Schema';
  # a schema always declares its driver (ADR 0067)
  __PACKAGE__->storage_type('+T::Driver::Storage');
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

{
  package T::Broker;
  use base 'DBIO::AccessBroker';
  sub new { my ($class, $answer) = @_; bless { answer => $answer }, $class }
  sub connect_info_for { $_[0]{answer}->() }
}

my $DSN     = 'dbi:K306Fake:dbname=k306-given';
my $ENV_DSN = 'dbi:K306Fake:k306-from-the-environment';
my %CRED    = (user => 'k306-user', password => 'k306-secret');
my %SERVER  = (host => 'k306-host.example', port => 'k306-port');
my $VALUE   = qr/k306-(?:user|secret|host|port|from-the-environment)/;

my @STORAGES = ('DBIO::Storage::DBI', 'T::Driver::Storage');
my @ENV_DSNS = (undef, $ENV_DSN);

sub env_label { defined $_[0] ? 'DBI_DSN set' : 'no DBI_DSN' }

# ---------------------------------------------------------------------------
# 1 + 2. Without a DSN: refused, and nothing to connect from afterwards.
# ---------------------------------------------------------------------------
my @WITHOUT = (
  [ 'no arguments'                      => sub { [] },
    'no arguments' ],
  [ 'the DBI form, DSN undef'           => sub { [ undef, @CRED{qw( user password )} ] },
    'the DBI form with an undefined DSN' ],
  [ 'the DBI form, DSN empty'           => sub { [ '', @CRED{qw( user password )} ] },
    'the DBI form with an empty DSN' ],
  [ 'the DBI form, DSN undef, attributes' => sub { [ undef, @CRED{qw( user password )}, { AutoCommit => 1 } ] },
    'the DBI form with an undefined DSN' ],
  [ 'a hash, dsn undef'                 => sub { [ { dsn => undef, %CRED } ] },
    'a hash with an undefined DSN' ],
  [ 'a hash, dsn empty'                 => sub { [ { dsn => '', %CRED } ] },
    'a hash with an empty DSN' ],
  [ 'a hash, dsn undef, host/port/user' => sub { [ { dsn => undef, %SERVER, %CRED } ] },
    'a hash with an undefined DSN' ],
  [ 'a hash, dsn empty, host/port/user' => sub { [ { dsn => '', %SERVER, %CRED } ] },
    'a hash with an empty DSN' ],
  [ 'a hash of user and password'       => sub { [ { %CRED } ] },
    'a hash with neither a dsn nor a dbname key' ],
  [ 'an empty hash'                     => sub { [ {} ] },
    'a hash with neither a dsn nor a dbname key' ],
);

for my $class (@STORAGES) {
  for my $env_dsn (@ENV_DSNS) {
    local %ENV = (%ENV, defined $env_dsn ? (DBI_DSN => $env_dsn) : ());

    for my $case (@WITHOUT) {
      my ($name, $info, $shape) = @$case;
      my $t = "$class, $name, " . env_label($env_dsn);

      local @CONNECTS;
      my $storage = $class->new(undef);

      throws_ok { $storage->connect_info($info->()) }
        qr/Connect info without a DSN \(\Q$shape\E\)/,
        "$t: refused at connect_info, naming the shape";
      unlike "$@", $VALUE, "$t: naming no value";
      like "$@", qr/never to the one in \$ENV\{DBI_DSN\}/, "$t: and that the environment is no substitute";

      throws_ok { $storage->_connect } qr/You did not provide any connection_info/,
        "$t: a connection after it has nothing to connect from";
      is scalar @CONNECTS, 0, "$t: DBI->connect is not called";
    }

    {
      my $t = "$class, never given connect info, " . env_label($env_dsn);
      local @CONNECTS;
      my $storage = $class->new(undef);
      throws_ok { $storage->_connect } qr/You did not provide any connection_info/,
        "$t: nothing to connect from";
      is scalar @CONNECTS, 0, "$t: DBI->connect is not called";
    }
  }
}

for my $env_dsn (@ENV_DSNS) {
  local %ENV = (%ENV, defined $env_dsn ? (DBI_DSN => $env_dsn) : ());
  my $t = 'Schema->connect, ' . env_label($env_dsn);
  local @CONNECTS;

  throws_ok { T::Schema->connect } qr/Connect info without a DSN \(no arguments\)/,
    "$t: without arguments refused";
  throws_ok { T::Schema->connect(undef, @CRED{qw( user password )}) }
    qr/Connect info without a DSN \(the DBI form with an undefined DSN\)/,
    "$t: with user and password alone refused";
  unlike "$@", $VALUE, "$t: naming no value";
  is scalar @CONNECTS, 0, "$t: DBI->connect is not called";
}

# ---------------------------------------------------------------------------
# 3. Code references and brokers carry no static DSN, and need none (control).
# ---------------------------------------------------------------------------
for my $class (@STORAGES) {
  for my $env_dsn (@ENV_DSNS) {
    local %ENV = (%ENV, defined $env_dsn ? (DBI_DSN => $env_dsn) : ());

    my $made = 0;
    my $maker = sub { $made++; T::Handle->new };

    my @UNJUDGED = (
      [ 'a code reference'                 => sub { [ $maker ] },                              'code' ],
      [ 'a code reference with attributes' => sub { [ $maker, { quote_names => 1 } ] },        'code' ],
      [ 'a dbh_maker in a hash'            => sub { [ { dbh_maker => $maker } ] },             'code' ],
      [ 'a broker answering a DSN'         =>
        sub { [ T::Broker->new(sub { +{ dsn => $DSN, %CRED } }) ] },                          'dsn'  ],
      [ 'a broker answering the DBI form'  =>
        sub { [ T::Broker->new(sub { [ $DSN, @CRED{qw( user password )} ] }) ] },             'dsn'  ],
      [ 'a broker answering a dbh_maker'   =>
        sub { [ T::Broker->new(sub { +{ dbh_maker => $maker } }) ] },                         'code' ],
    );

    for my $case (@UNJUDGED) {
      my ($name, $info, $by) = @$case;
      my $t = "$class, $name, " . env_label($env_dsn);

      local @CONNECTS;
      $made = 0;
      my $storage = $class->new(undef);

      lives_ok { $storage->connect_info($info->()) } "$t: connect_info takes it";
      lives_ok { $storage->_connect } "$t: and it connects";

      if ($by eq 'code') {
        is $made, 1, "$t: by the code";
        is scalar @CONNECTS, 0, "$t: DBI->connect is not called";
      }
      else {
        is scalar @CONNECTS, 1, "$t: DBI->connect is called once";
        is $CONNECTS[0][0], $DSN, "$t: with the DSN the broker answered";
      }
    }

    for my $case (
      [ 'a hash of user and password' => sub { +{ %CRED } },
        'a hash with neither a dsn nor a dbname key' ],
      [ 'the DBI form, DSN undef'     => sub { [ undef, @CRED{qw( user password )} ] },
        'the DBI form with an undefined DSN' ],
    ) {
      my ($name, $answer, $shape) = @$case;
      my $t = "$class, a broker answering $name, " . env_label($env_dsn);

      local @CONNECTS;
      my $storage = $class->new(undef);
      throws_ok { $storage->connect_info([ T::Broker->new($answer) ]) }
        qr/AccessBroker T::Broker answered connect info without a DSN \(\Q$shape\E\)/,
        "$t: the broker's own refusal, naming the broker class";
      is scalar @CONNECTS, 0, "$t: DBI->connect is not called";
    }
  }
}

# ---------------------------------------------------------------------------
# 4. A dbname key names the database by its parts: the DSN is built (control).
# ---------------------------------------------------------------------------
for my $env_dsn (@ENV_DSNS) {
  local %ENV = (%ENV, defined $env_dsn ? (DBI_DSN => $env_dsn) : ());
  my $t = 'T::Driver::Storage, a hash with a dbname key, ' . env_label($env_dsn);

  local @CONNECTS;
  my $storage = T::Driver::Storage->new(undef);
  lives_ok { $storage->connect_info([ { dbname => 'app', %SERVER, %CRED } ]) }
    "$t: connect_info takes it";
  lives_ok { $storage->_connect } "$t: and it connects";
  is $CONNECTS[0][0], "dbi:K306Fake:dbname=app;host=$SERVER{host};port=$SERVER{port}",
    "$t: to the DSN built for the storage's driver";
}

done_testing;
