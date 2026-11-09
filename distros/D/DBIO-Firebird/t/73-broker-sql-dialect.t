use strict;
use warnings;
use Test::More;

use DBI;
use DBIO::AccessBroker;
use DBIO::AccessBroker::Static;
use DBIO::Firebird::Storage;
use DBIO::Firebird::Storage::InterBase;
use DBIO::Firebird::Storage::ODBC;

# OFFLINE (karr k43).
#
# WHY: SQL dialect 3 is what makes quoted identifiers and the modern types
# work, and DBD::InterBase takes dialect 1 when the DSN does not say
# ib_dialect=3 (DBD::Firebird and DBD::InterBase read it from the DSN alone,
# not from the attribute hash). Without a broker the storage writes it into its
# own connect info. With a broker nothing of the answer is stored (core k266):
# the old rewrite changed a throw-away copy, the storage then disconnected and
# connected anew, and both connections went to the DSN the broker answered, as
# it answered it -- dialect 1 over DBD::InterBase, without a word.
#
# What this file claims:
#   1. The DSN of the connection a broker's answer opens carries ib_dialect=3,
#      whichever form the answer has (DBI form, hash with dsn, the
#      connection parameters of Static, settings beside the broker) and on both
#      native storages.
#   2. It is one connection, opened once: forcing the dialect reconnects only
#      where it rewrites a stored DSN, and with a broker there is none.
#   3. A dialect 3 the answer names itself, spelled as the DBD reads it
#      (key exactly ib_dialect), stays; spelled otherwise (IB_DIALECT=3,
#      'ib_dialect = 3') the DBD reads nothing and ;ib_dialect=3 is appended; a DSN of
#      another DBD (ODBC) and a code reference are not rewritten; the ODBC
#      storage never adds it.
#   3a. An answer that names another dialect than 3 -- in the DSN, in any
#      letter case, or as an ib_dialect attribute (which the DBD drops without
#      a word) -- is refused loudly, without the DSN or the password in the
#      message; an ib_dialect => 3 attribute alone gets the DSN's ib_dialect=3.
#   4. Without a broker it is as it was: the stored DSN carries the dialect.
#
# THE SUBSTITUTIONS: DBI->connect is a recorder returning a stand-in handle;
# no DBD connects and no database is involved.

delete @ENV{qw( DBI_DSN DBI_DRIVER )};

{
  package T::Broker;
  use base 'DBIO::AccessBroker';
  sub new { my ($class, $answer) = @_; bless { answer => $answer }, $class }
  sub connect_info_for { $_[0]{answer}->() }
}

{
  package T::Handle;
  sub new   { bless { Active => 1, AutoCommit => 1, RaiseError => 1 }, shift }
  sub FETCH { $_[0]->{ $_[1] } }
  sub disconnect { 1 }
  sub get_info   { 0 }
}

our @CONNECTS;
{
  no warnings 'redefine';
  *DBI::connect = sub { shift; push @CONNECTS, [ @_ ]; T::Handle->new };
}

# Every native connection also gets ib_charset=UTF8 (karr k60, t/93-utf8-connection.t);
# this file is about the dialect, so the charset is taken off before comparing.
sub no_charset { return $_[0] =~ s{;ib_charset=UTF8\z}{}r }

my %LOGIN = (user => 'k43-user', password => 'k43-secret');
my $PATH  = '/k43/data/app.fdb';

sub storage_with {
  my ($class, @info) = @_;
  my $storage = $class->new(undef);
  $storage->connect_info([ @info ]);
  return $storage;
}

# Everything the storage connects with when it is first used, as the list of
# DSNs DBI->connect saw.
sub dsns_connected {
  my ($storage) = @_;
  local @CONNECTS;
  $storage->_determine_driver;
  $storage->ensure_connected;
  return map { no_charset($_->[0]) } @CONNECTS;
}

for my $class (qw( DBIO::Firebird::Storage DBIO::Firebird::Storage::InterBase )) {
  for my $case (
    [ 'DBI form answer',
      sub { [ "dbi:Firebird:dbname=$PATH;host=h", @LOGIN{qw(user password)}, {} ] },
      "dbi:Firebird:dbname=$PATH;host=h;ib_dialect=3" ],
    [ 'hash answer carrying a dsn',
      sub { { dsn => "dbi:Firebird:dbname=$PATH", %LOGIN } },
      "dbi:Firebird:dbname=$PATH;ib_dialect=3" ],
    [ 'DBD::InterBase DSN',
      sub { { dsn => "dbi:InterBase:dbname=$PATH", %LOGIN } },
      "dbi:InterBase:dbname=$PATH;ib_dialect=3" ],
  ) {
    my ($label, $answer, $expected) = @$case;
    my $storage = storage_with($class, T::Broker->new($answer));
    my @dsns = dsns_connected($storage);
    is_deeply \@dsns, [ $expected ], "$class, $label: one connection, with ib_dialect=3";
    is $storage->_dbi_connect_info->[0] =~ s{;ib_charset=UTF8\z}{}r, $expected,
      '... and the connect info the storage reads says the same';
  }

  {
    my $storage = storage_with($class,
      DBIO::AccessBroker::Static->new(dbname => $PATH, host => 'h', port => 3050,
        username => 'u', password => 'p'),
      { ib_softcommit => 1 });
    # the DSN is built for the DBD the storage class is registered for
    my $dbd = $class =~ /InterBase$/ ? 'InterBase' : 'Firebird';
    is_deeply [ dsns_connected($storage) ],
      [ "dbi:$dbd:dbname=$PATH;host=h;port=3050;ib_dialect=3" ],
      "$class, Static (connection parameters) with an attribute beside it: one connection, with ib_dialect=3";
  }

  {
    my $storage = storage_with($class,
      T::Broker->new(sub { { dsn => "dbi:Firebird:dbname=$PATH", %LOGIN } }));
    local @CONNECTS;
    $storage->ensure_connected;
    $storage->disconnect;
    $storage->ensure_connected;
    is_deeply [ map { no_charset($_->[0]) } @CONNECTS ], [ ("dbi:Firebird:dbname=$PATH;ib_dialect=3") x 2 ],
      "$class: a connection opened later gets it as well";
  }

  for my $spelling ('ib_dialect=3') {
    my $storage = storage_with($class, T::Broker->new(
      sub { [ "dbi:Firebird:dbname=$PATH;$spelling", @LOGIN{qw(user password)} ] }));
    is_deeply [ dsns_connected($storage) ], [ "dbi:Firebird:dbname=$PATH;$spelling" ],
      "$class: a dialect 3 the broker names itself ($spelling) stays, none added";
  }

  # the DBD's parser compares the key with eq and trims nothing: these are
  # other keys to it, it reads no dialect, so ours is appended (not refused)
  for my $spelling ('IB_DIALECT=3', 'ib_dialect = 3', 'Ib_Dialect=3') {
    my $storage = storage_with($class, T::Broker->new(
      sub { [ "dbi:Firebird:dbname=$PATH;$spelling", @LOGIN{qw(user password)} ] }));
    is_deeply [ dsns_connected($storage) ], [ "dbi:Firebird:dbname=$PATH;$spelling;ib_dialect=3" ],
      "$class: ($spelling) is not read by the DBD, ib_dialect=3 is appended";
  }

  for my $case (
    [ 'DSN ib_dialect=1',
      sub { [ "dbi:Firebird:dbname=$PATH;ib_dialect=1", @LOGIN{qw(user password)} ] }, 'the DSN' ],
    [ 'DSN IB_DIALECT=1 (upper case)',
      sub { [ "dbi:Firebird:dbname=$PATH;IB_DIALECT=1", @LOGIN{qw(user password)} ] }, 'the DSN' ],
    [ 'DSN ib_dialect=2 after a host',
      sub { [ "dbi:InterBase:host=h;dbname=$PATH;ib_dialect=2", @LOGIN{qw(user password)} ] }, 'the DSN' ],
    [ 'DSN of a hash answer',
      sub { { dsn => "dbi:Firebird:dbname=$PATH;ib_dialect=1", %LOGIN } }, 'the DSN' ],
    [ 'ib_dialect attribute of a DBI form answer',
      sub { [ "dbi:Firebird:dbname=$PATH", @LOGIN{qw(user password)}, { ib_dialect => 1 } ] }, 'the attributes' ],
    [ 'ib_dialect attribute of a hash answer',
      sub { { dsn => "dbi:Firebird:dbname=$PATH", %LOGIN, ib_dialect => 1 } }, 'the attributes' ],
    [ 'IB_Dialect attribute (letter case)',
      sub { [ "dbi:Firebird:dbname=$PATH", @LOGIN{qw(user password)}, { IB_Dialect => 1 } ] }, 'the attributes' ],
  ) {
    my ($label, $answer, $where) = @$case;
    my $storage = storage_with($class, T::Broker->new($answer));
    local @CONNECTS;
    my $ok = eval { $storage->_determine_driver; $storage->ensure_connected; 1 };
    my $error = "$@";
    ok !$ok, "$class, $label: refused";
    like $error, qr/ib_dialect other than 3 \(in \Q$where\E\)/, "... naming $where";
    unlike $error, qr/\Q$PATH\E|k43-secret|k43-user/, '... with no DSN, user or password in the message';
    is scalar @CONNECTS, 0, '... and no connection was opened';
  }

  {
    my $storage = storage_with($class, T::Broker->new(
      sub { [ "dbi:Firebird:dbname=$PATH", @LOGIN{qw(user password)}, { ib_dialect => 3 } ] }));
    is_deeply [ dsns_connected($storage) ], [ "dbi:Firebird:dbname=$PATH;ib_dialect=3" ],
      "$class: an ib_dialect => 3 attribute alone gets the dialect into the DSN, which the DBD reads";
  }

  {
    my $storage = storage_with($class, T::Broker->new(
      sub { [ "dbi:ODBC:Driver=Firebird;Dbname=$PATH", @LOGIN{qw(user password)} ] }));
    # a native storage over an ODBC DSN warns of the mismatch (core ADR 0059)
    my @dsns = do { local $SIG{__WARN__} = sub {}; dsns_connected($storage) };
    is_deeply \@dsns, [ "dbi:ODBC:Driver=Firebird;Dbname=$PATH" ],
      "$class: the DSN of another DBD is not rewritten";
  }

  {
    my $made = 0;
    my $storage = storage_with($class, T::Broker->new(
      sub { [ sub { $made++; T::Handle->new } ] }));
    local @CONNECTS;
    $storage->ensure_connected;
    is $made, 1, "$class: a connection coderef is called once, as it is";
    is scalar @CONNECTS, 0, '... and DBI->connect is not involved';
  }

  {
    my $storage = $class->new(undef);
    $storage->connect_info([ "dbi:Firebird:dbname=$PATH", @LOGIN{qw(user password)} ]);
    $storage->_determine_driver;
    is $storage->_dbi_connect_info->[0] =~ s{;ib_charset=UTF8\z}{}r, "dbi:Firebird:dbname=$PATH;ib_dialect=3",
      "$class, no broker: the stored DSN carries the dialect, as before";
  }
}

{
  my $storage = storage_with('DBIO::Firebird::Storage::ODBC', T::Broker->new(
    sub { [ "dbi:ODBC:Driver=Firebird;Dbname=$PATH", @LOGIN{qw(user password)} ] }));
  is_deeply [ dsns_connected($storage) ], [ "dbi:ODBC:Driver=Firebird;Dbname=$PATH" ],
    'the ODBC storage adds no ib_ attribute';
}

done_testing;
