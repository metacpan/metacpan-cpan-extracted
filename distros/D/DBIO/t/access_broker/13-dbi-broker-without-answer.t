# ABSTRACT: A sync storage refuses a broker that answers nothing
use strict;
use warnings;

use Test::More;
use Test::Exception;

use DBI;
use DBIO::Storage::DBI;
use DBIO::AccessBroker;

# OFFLINE (karr k250, the sync twin of k249). DBIO::Storage::DBI asks its
# AccessBroker at connect_info and again for every new connection
# (_current_dbi_connect_info). When the broker answered nothing it fell back to
# the DBI connect info stored from an EARLIER answer without a word: a broker
# answering [ $dsn, 'user_1', 'secret_1' ] and then undef got a DBI->connect as
# user_1 with secret_1 -- the credentials it may just have rotated out. Asked at
# connect_info on a storage connected statically before, the fallback reused
# the previous connection's identity.
#
# What this file claims:
#   1. A broker that answers nothing when a new connection is opened fails that
#      connection: _connect throws an error naming the broker class and what it
#      answered, never a value of an earlier answer, and DBI->connect is never
#      called. A good answer before it is still used (control).
#   2. A broker that answers nothing at connect_info makes connect_info throw
#      the same error. On a storage connected statically before, the next
#      connection is not opened with the static identity either.
#   3. A broker that throws: its own error reaches the caller, at connect_info
#      and at _connect; DBI->connect is never called.
#   4. Without a broker, a connection still gets the static connect info
#      connect_info stored -- the fallback's own purpose.
#   5. The refusal belongs to current_access_broker_connect_info itself -- the
#      one method every storage asks, and the one the async transports of the
#      drivers read directly -- not to one caller of it.
#
# THE SUBSTITUTIONS: DBI->connect is replaced by a recorder returning a stand-in
# handle; no database is involved, and the DSNs name no real driver.

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
  package T::Handle;
  sub new   { bless { Active => 1, AutoCommit => 1, RaiseError => 1 }, shift }
  sub FETCH { $_[0]->{ $_[1] } }
}

our @CONNECTS;
{
  no warnings 'redefine';
  *DBI::connect = sub { shift; push @CONNECTS, [ @_ ]; T::Handle->new };
}

my $SECRET = qr/k250-(?:user|secret|old)/;

sub answer { my $n = shift; [ "dbi:Fake:k250-$n", "k250-user-$n", "k250-secret-$n", {} ] }

my %NOTHING = (
  'undef'             => sub { undef },
  'an empty hashref'  => sub { {} },
  'an empty arrayref' => sub { [] },
  'a false value'     => sub { '' },
);

sub nothing_answered { qr/AccessBroker T::ScriptBroker answered no connect info \(\Q$_[0]\E\)/ }

# ---------------------------------------------------------------------------
# 1. Nothing answered when a connection is opened.
# ---------------------------------------------------------------------------
for my $shape (sort keys %NOTHING) {
  my $storage = DBIO::Storage::DBI->new(undef);
  $storage->connect_info([ T::ScriptBroker->new(
    sub { answer(1) }, sub { answer(2) }, $NOTHING{$shape},
  ) ]);
  local @CONNECTS;

  lives_ok { $storage->_connect } "$shape: a connection before it is opened";
  is_deeply [ map { [ @$_[0 .. 2] ] } @CONNECTS ],
    [ [ 'dbi:Fake:k250-2', 'k250-user-2', 'k250-secret-2' ] ],
    "$shape: ... with the broker's current answer";

  throws_ok { $storage->_connect } nothing_answered($shape),
    "$shape: the next connection throws, naming the broker class and what it answered";
  unlike "$@", $SECRET, "$shape: naming no value of an earlier answer";
  is scalar @CONNECTS, 1, "$shape: DBI->connect is not called with an earlier answer";
}

# ---------------------------------------------------------------------------
# 2. Nothing answered at connect_info.
# ---------------------------------------------------------------------------
for my $shape (sort keys %NOTHING) {
  my $storage = DBIO::Storage::DBI->new(undef);
  throws_ok { $storage->connect_info([ T::ScriptBroker->new($NOTHING{$shape}) ]) }
    nothing_answered($shape), "$shape at connect_info: connect_info throws";
}

{
  my $storage = DBIO::Storage::DBI->new(undef);
  $storage->connect_info([ 'dbi:Fake:k250-old', 'k250-old-user', 'k250-old-pw' ]);
  throws_ok { $storage->connect_info([ T::ScriptBroker->new(sub { undef }) ]) }
    nothing_answered('undef'),
    'a statically connected storage, reconnected with a broker answering nothing: connect_info throws';
  unlike "$@", $SECRET, '... naming no value of the previous connect info';

  local @CONNECTS;
  throws_ok { $storage->_connect } nothing_answered('undef'),
    '... and its next connection throws too';
  is scalar @CONNECTS, 0, '... without DBI->connect as the previous identity';
}

# ---------------------------------------------------------------------------
# 3. The broker throws.
# ---------------------------------------------------------------------------
{
  my $storage = DBIO::Storage::DBI->new(undef);
  throws_ok { $storage->connect_info([ T::ScriptBroker->new(sub { die "k250 vault unreachable\n" }) ]) }
    qr/^k250 vault unreachable/, 'a broker throwing at connect_info: its error reaches the caller';
}

{
  my $storage = DBIO::Storage::DBI->new(undef);
  $storage->connect_info([ T::ScriptBroker->new(sub { answer(1) }, sub { die "k250 vault unreachable\n" }) ]);
  local @CONNECTS;
  throws_ok { $storage->_connect } qr/^k250 vault unreachable/,
    'a broker throwing at a connection: its error reaches the caller';
  is scalar @CONNECTS, 0, '... and DBI->connect is not called with the earlier answer';
}

# ---------------------------------------------------------------------------
# 4. No broker: the static connect info.
# ---------------------------------------------------------------------------
{
  my $storage = DBIO::Storage::DBI->new(undef);
  $storage->connect_info([ 'dbi:Fake:k250-static', 'static-user', 'static-pw' ]);
  local @CONNECTS;
  lives_ok { $storage->_connect } 'without a broker, a connection is opened';
  is_deeply [ @{ $CONNECTS[0] }[0 .. 2] ], [ 'dbi:Fake:k250-static', 'static-user', 'static-pw' ],
    '... with the connect info connect_info stored';
}

# ---------------------------------------------------------------------------
# 5. The one place.
# ---------------------------------------------------------------------------
{
  my $storage = DBIO::Storage::DBI->new(undef);
  is_deeply [ $storage->current_access_broker_connect_info('write') ], [],
    'current_access_broker_connect_info without a broker answers nothing, and throws nothing';

  $storage->set_access_broker(T::ScriptBroker->new(sub { answer(1) }, sub { undef }));
  is_deeply $storage->current_access_broker_connect_info('write'), answer(1),
    'current_access_broker_connect_info hands on a broker answer';
  throws_ok { $storage->current_access_broker_connect_info('write') } nothing_answered('undef'),
    'current_access_broker_connect_info itself refuses a broker answering nothing';
}

done_testing;
