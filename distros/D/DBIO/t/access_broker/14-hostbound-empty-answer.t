# ABSTRACT: A HostBound view hands an empty broker answer on unchanged, so it is refused
use strict;
use warnings;

use Test::More;
use Test::Exception;

use DBI;
use DBIO::Storage::DBI;
use DBIO::AccessBroker;

# OFFLINE (karr k253, a gap in k250). A storage refuses a broker that answers
# nothing -- undef, an empty hash or array, a false value -- in
# DBIO::Storage::current_access_broker_connect_info. A HostBound view (what
# $broker->for_host($host) builds, one per replicant) binds its host and port
# into the answer of the broker it wraps. It did that to an empty hash too: the
# wrapped broker answered {}, the view answered { host => ..., port => ... },
# which is not empty, so the refusal never fired and the connection was opened
# with host and port alone -- the DBD's environment defaults for everything
# else, database and identity included.
#
# What this file claims:
#   1. A view over a broker that answers nothing answers that same nothing:
#      an empty hash stays an empty hash, and undef, an empty array and a
#      false value are handed on as they came (connect_info_for and
#      connect_info_for_storage alike).
#   2. A storage asking through such a view refuses -- at connect_info and at
#      the next connection -- and the error names the broker that answered
#      nothing and the view it was asked through; DBI->connect is not called.
#   3. Control: an answer that is not empty still gets the view's host and
#      port bound in, in both shapes.
#
# THE SUBSTITUTIONS: DBI->connect is replaced by a recorder returning a
# stand-in handle; no database is involved, and the DSNs name no real driver.

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

my %NOTHING = (
  'undef'             => sub { undef },
  'an empty hashref'  => sub { {} },
  'an empty arrayref' => sub { [] },
  'a false value'     => sub { '' },
);

sub view_over { T::ScriptBroker->new(@_)->for_host({ host => 'replica-k253', port => 6543 }) }

sub nothing_through_view {
  qr/AccessBroker T::ScriptBroker answered no connect info \(\Q$_[0]\E\) through DBIO::AccessBroker::HostBound\./
}

# ---------------------------------------------------------------------------
# 1. The view hands nothing on as nothing.
# ---------------------------------------------------------------------------
for my $shape (sort keys %NOTHING) {
  my $expected = $NOTHING{$shape}->();
  is_deeply view_over($NOTHING{$shape})->connect_info_for('write'), $expected,
    "$shape: connect_info_for hands the wrapped broker's answer on unchanged";
  is_deeply view_over($NOTHING{$shape})->connect_info_for_storage(undef, 'write'), $expected,
    "$shape: connect_info_for_storage hands it on unchanged";
}

# ---------------------------------------------------------------------------
# 2. A storage asking through the view refuses.
# ---------------------------------------------------------------------------
for my $shape (sort keys %NOTHING) {
  my $storage = DBIO::Storage::DBI->new(undef);
  local @CONNECTS;
  throws_ok { $storage->connect_info([ view_over($NOTHING{$shape}) ]) }
    nothing_through_view($shape),
    "$shape at connect_info: throws, naming the broker that answered and the view";
  unlike "$@", qr/replica-k253|6543/, "$shape: ... naming no host the view would have bound in";
}

for my $shape (sort keys %NOTHING) {
  my $storage = DBIO::Storage::DBI->new(undef);
  $storage->connect_info([ view_over(
    sub { [ 'dbi:Fake:dbname=k253', 'k253-user', 'k253-secret', {} ] },
    $NOTHING{$shape},
  ) ]);
  local @CONNECTS;
  throws_ok { $storage->_connect } nothing_through_view($shape),
    "$shape at a new connection: throws, naming the broker that answered and the view";
  is scalar @CONNECTS, 0, "$shape: ... and DBI->connect is not called";
}

{
  my $storage = DBIO::Storage::DBI->new(undef);
  $storage->set_access_broker(view_over(sub { {} })->for_host('outer-k253'));
  throws_ok { $storage->current_access_broker_connect_info('write') }
    qr/AccessBroker T::ScriptBroker answered no connect info \(an empty hashref\) through DBIO::AccessBroker::HostBound over DBIO::AccessBroker::HostBound\./,
    'a view over a view: the error names the broker at the bottom and both views';
}

# ---------------------------------------------------------------------------
# 3. Control: an answer that is not empty gets the host bound in.
# ---------------------------------------------------------------------------
is_deeply view_over(sub { { dbname => 'k253' } })->connect_info_for('write'),
  { dbname => 'k253', host => 'replica-k253', port => 6543 },
  'a hash answer that is not empty gets the view\'s host and port';
is_deeply view_over(sub { [ 'dbi:Fake:dbname=k253', 'u', 'p' ] })->connect_info_for('write'),
  [ 'dbi:Fake:port=6543;host=replica-k253;dbname=k253', 'u', 'p' ],
  'a DBI-form answer gets them in its DSN';

{
  my $storage = DBIO::Storage::DBI->new(undef);
  local @CONNECTS;
  $storage->connect_info([ view_over(sub { [ 'dbi:Fake:dbname=k253', 'k253-user', 'k253-secret', {} ] }) ]);
  lives_ok { $storage->_connect } 'a storage asking through the view connects with a good answer';
  is $CONNECTS[0][0], 'dbi:Fake:port=6543;host=replica-k253;dbname=k253',
    '... to the view\'s host';
}

done_testing;
