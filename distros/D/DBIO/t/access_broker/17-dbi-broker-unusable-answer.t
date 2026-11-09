# ABSTRACT: A sync storage and the broker answers it cannot connect from
use strict;
use warnings;

use Test::More;
use Test::Exception;

use DBI;
use DBIO::Storage::DBI;
use DBIO::AccessBroker;

# OFFLINE (karr k270; the sync twin of k264). 13-dbi-broker-without-answer.t
# covers a broker that answers NOTHING (undef, {}, [], a false value). This
# file is about the answers that are something, and still nothing a
# DBI->connect can be made from.
#
# What this file claims:
#   1. An answer that is neither a hash nor an array -- a plain scalar, a code
#      reference, a scalar reference, an object -- is refused, at connect_info
#      and at every later connection, attached directly or through a HostBound
#      view: the error names the broker class and the SHAPE of the answer,
#      never a value of it, and DBI->connect is not called. (Before k270 a
#      plain string died in an array dereference whose message quoted the
#      string -- a DSN, which may carry a password.)
#   2. The two shapes a DBI storage takes still connect (control).
#   3. An answer with credentials but no DSN -- a hash of user and password, a
#      hash of host and port without a dbname key, a hash or the DBI form with
#      an undef or empty DSN -- is refused the same way: at connect_info and at
#      every later connection, attached directly or through a HostBound view,
#      naming the broker class and the shape, never a value, and DBI->connect
#      is not called (karr k271; maintainer's decision 2026-10-06). WHY: the
#      credentials are the broker's, for the database the broker names. Left
#      alone, an undef DSN falls back to $ENV{DBI_DSN} in the storage and an
#      empty one in DBI->connect itself -- the broker's user and password
#      would go to a server the broker never named. So the environment is no
#      way around the refusal, and a storage with a broker attached does not
#      take the DSN of the environment for its own.
#
# THE SUBSTITUTIONS: DBI->connect is replaced by a recorder returning a stand-in
# handle; a fake driver storage registered for the DBD name 'K270Fake'; no
# database is involved.

delete @ENV{qw( DBI_DSN DBI_DRIVER )};

# A broker answering from a script: one code per call, the last one repeating.
{
  package T::ScriptBroker;
  use base 'DBIO::AccessBroker';
  sub new { my ($class, @answers) = @_; bless { answers => \@answers, calls => 0 }, $class }
  sub connect_info_for {
    my $self = shift;
    my $i = $self->{calls}++;
    $i = $#{ $self->{answers} } if $i > $#{ $self->{answers} };
    return $self->{answers}[$i]->();
  }
}

{
  package T::Driver::Storage;
  use base 'DBIO::Storage::DBI';
  DBIO::Storage::DBI->register_driver(K270Fake => __PACKAGE__);
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

my ($USER, $PASSWORD) = ('k270-user', 'k270-secret');
my $VALUE = qr/k270-(?:user|secret|dsn|host|port)/;   # every value of an answer in this file

my @STORAGES = ('DBIO::Storage::DBI', 'T::Driver::Storage');
my $ENV_DSN  = 'dbi:K270Fake:from-the-environment';

sub good_answer { [ 'dbi:K270Fake:k270-dsn-good', $USER, $PASSWORD, {} ] }

# ---------------------------------------------------------------------------
# 1. Neither a hash nor an array.
# ---------------------------------------------------------------------------
my %NO_SHAPE = (
  'a plain scalar'            => sub { "dbi:K270Fake:k270-dsn;user=$USER;password=$PASSWORD" },
  'a CODE reference'          => sub { sub { T::Handle->new } },
  'a SCALAR reference'        => sub { \"dbi:K270Fake:k270-dsn" },
  'an object of class T::Answer' => sub { bless { dsn => 'dbi:K270Fake:k270-dsn', password => $PASSWORD }, 'T::Answer' },
);

sub cannot_use {
  my ($broker_class, $shape) = @_;
  return qr/AccessBroker \Q$broker_class\E answered connect info a DBI storage cannot connect from \(\Q$shape\E\)/;
}

for my $class (@STORAGES) {
  for my $shape (sort keys %NO_SHAPE) {
    my $t = "$class, $shape";

    # a DSN in the environment is no way around the refusal
    local $ENV{DBI_DSN} = $ENV_DSN;

    {
      my $storage = $class->new(undef);
      local @CONNECTS;
      throws_ok { $storage->connect_info([ T::ScriptBroker->new($NO_SHAPE{$shape}) ]) }
        cannot_use('T::ScriptBroker', $shape),
        "$t at connect_info: throws, naming the broker class and the shape";
      unlike "$@", $VALUE, "$t at connect_info: naming no value of the answer";
      throws_ok { $storage->_connect } cannot_use('T::ScriptBroker', $shape),
        "$t: a connection after it throws the same";
      is scalar @CONNECTS, 0, "$t: DBI->connect is not called";
    }

    {
      my $storage = $class->new(undef);
      $storage->connect_info([ T::ScriptBroker->new(\&good_answer, \&good_answer, $NO_SHAPE{$shape}) ]);
      local @CONNECTS;
      lives_ok { $storage->_connect } "$t as a later answer: a connection before it is opened";
      throws_ok { $storage->_connect } cannot_use('T::ScriptBroker', $shape),
        "$t as a later answer: the next connection throws";
      unlike "$@", $VALUE, "$t as a later answer: naming no value, of this answer or an earlier one";
      is scalar @CONNECTS, 1, "$t as a later answer: DBI->connect is not called again";
    }

    {
      my $storage = $class->new(undef);
      my $view = T::ScriptBroker->new($NO_SHAPE{$shape})->for_host('replica.example');
      local @CONNECTS;
      throws_ok { $storage->connect_info([ $view ]) }
        cannot_use('DBIO::AccessBroker::HostBound', $shape),
        "$t through a HostBound view: throws, naming the view and the shape";
      unlike "$@", $VALUE, "$t through a HostBound view: naming no value of the answer";
      is scalar @CONNECTS, 0, "$t through a HostBound view: DBI->connect is not called";
    }
  }
}

# ---------------------------------------------------------------------------
# 2. The shapes a DBI storage takes (control).
# ---------------------------------------------------------------------------
for my $class (@STORAGES) {
  my $storage = $class->new(undef);
  $storage->connect_info([ T::ScriptBroker->new(\&good_answer) ]);
  local @CONNECTS;
  lives_ok { $storage->_connect } "$class: the DBI form connects";
  is_deeply [ @{ $CONNECTS[0] }[0 .. 2] ], [ @{ good_answer() }[0 .. 2] ],
    "$class: ... with the answer";
}

{
  my $storage = T::Driver::Storage->new(undef);
  $storage->connect_info([ T::ScriptBroker->new(
    sub { { dbname => 'app', host => 'db.example', user => $USER, password => $PASSWORD } },
  ) ]);
  local @CONNECTS;
  lives_ok { $storage->_connect } 'a hash of connection parameters connects on a driver storage';
  is_deeply [ @{ $CONNECTS[0] }[0 .. 2] ],
    [ 'dbi:K270Fake:dbname=app;host=db.example', $USER, $PASSWORD ],
    '... with the DSN built for the driver';
}

# ---------------------------------------------------------------------------
# 3. Credentials, but no DSN.
# ---------------------------------------------------------------------------
# shape => [ answer, the shape the error names, the same through a HostBound
# view -- which binds its host into a hash ]. The port is a marker, not a
# number: a number may turn up in the path an error message ends with.
my $NEITHER = 'neither a dsn nor a dbname key';
my %NO_DSN = (
  'a hash of user and password' => [
    sub { { user => $USER, password => $PASSWORD } },
    "a hash with $NEITHER", "a hash with host, but $NEITHER",
  ],
  'a hash of host, port, user and password without a dbname key' => [
    sub { { host => 'k270-host', port => 'k270-port', user => $USER, password => $PASSWORD } },
    ("a hash with host and port, but $NEITHER") x 2,
  ],
  'a hash with an undef dsn' => [
    sub { { dsn => undef, user => $USER, password => $PASSWORD } },
    ('a hash with an undefined DSN') x 2,
  ],
  'a hash with an empty dsn beside a dbname' => [
    sub { { dsn => '', dbname => 'k270-dsn-db', user => $USER, password => $PASSWORD } },
    ('a hash with an empty DSN') x 2,
  ],
  'the DBI form with an undef DSN' => [
    sub { [ undef, $USER, $PASSWORD ] },
    ('the DBI form with an undefined DSN') x 2,
  ],
  'the DBI form with an empty DSN' => [
    sub { [ '', $USER, $PASSWORD ] },
    ('the DBI form with an empty DSN') x 2,
  ],
);

sub no_dsn {
  my ($broker_class, $shape) = @_;
  return qr/AccessBroker \Q$broker_class\E answered connect info without a DSN \(\Q$shape\E\)/;
}

for my $class (@STORAGES) {
  for my $shape (sort keys %NO_DSN) {
    my ($answer, $direct, $through_view) = @{ $NO_DSN{$shape} };

    # with a DSN in the environment and without: refused either way
    for my $env_dsn (undef, $ENV_DSN) {
      local %ENV = (%ENV, defined $env_dsn ? (DBI_DSN => $env_dsn) : ());
      my $t = "$class, $shape, " . (defined $env_dsn ? 'DBI_DSN set' : 'no DBI_DSN');

      {
        my $storage = $class->new(undef);
        local @CONNECTS;
        throws_ok { $storage->connect_info([ T::ScriptBroker->new($answer) ]) }
          no_dsn('T::ScriptBroker', $direct),
          "$t at connect_info: throws, naming the broker class and the shape";
        unlike "$@", $VALUE, "$t at connect_info: naming no value of the answer";
        throws_ok { $storage->_connect } no_dsn('T::ScriptBroker', $direct),
          "$t: a connection after it throws the same";
        is scalar @CONNECTS, 0,
          "$t: DBI->connect is not called -- the broker's credentials go to no DSN it did not give";
        # karr k266: the storage holds no answer, so reading its connect info
        # asks the broker, and an unusable answer is refused there as well --
        # a stricter form of the claim (it used to read the empty stored info):
        # the DSN of the environment is still not taken for the storage's own.
        throws_ok { $storage->_dbi_connect_info } no_dsn('T::ScriptBroker', $direct),
          "$t: reading the connect info refuses the answer, and does not hand out the DSN of the environment";
      }

      {
        my $storage = $class->new(undef);
        $storage->connect_info([ T::ScriptBroker->new(\&good_answer, \&good_answer, $answer) ]);
        local @CONNECTS;
        lives_ok { $storage->_connect } "$t as a later answer: a connection before it is opened";
        throws_ok { $storage->_connect } no_dsn('T::ScriptBroker', $direct),
          "$t as a later answer: the next connection throws";
        unlike "$@", $VALUE, "$t as a later answer: naming no value, of this answer or an earlier one";
        is scalar @CONNECTS, 1, "$t as a later answer: DBI->connect is not called again";
      }

      {
        my $storage = $class->new(undef);
        my $view = T::ScriptBroker->new($answer)->for_host('k270-host-replica');
        local @CONNECTS;
        throws_ok { $storage->connect_info([ $view ]) }
          no_dsn('DBIO::AccessBroker::HostBound', $through_view),
          "$t through a HostBound view: throws, naming the view and the shape";
        unlike "$@", $VALUE, "$t through a HostBound view: naming no value of the answer";
        throws_ok { $storage->_connect } no_dsn('DBIO::AccessBroker::HostBound', $through_view),
          "$t through a HostBound view: a connection after it throws the same";
        is scalar @CONNECTS, 0, "$t through a HostBound view: DBI->connect is not called";
      }
    }
  }
}

done_testing;
