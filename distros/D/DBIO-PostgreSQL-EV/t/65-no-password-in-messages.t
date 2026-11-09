use strict;
use warnings;
use Test::More;

# OFFLINE test: no message of this transport about a connection quotes its
# password (karr k78; core k297 for the sync side).
#
# WHY: a message about a connection that cannot be opened ends where nobody
# guards it -- a log, a bug report, the exception page of a web application.
# Core masks the password wherever it writes connect info into a message, with
# one function for it, DBIO::Util::mask_connect_secrets. This transport writes
# connect info into messages of its own, and passes on libpq's, which quotes
# what it could not read:
#
#   1. connect info the transport cannot connect from is refused by
#      connect_info, naming its form -- for the DBI form the DBI driver, for a
#      hash its keys, for an array what kind of thing each element is -- and
#      no value of it, wherever in it the password stands (karr k66). Through
#      a schema that is the first ->async. (What dbi_to_conninfo itself says,
#      which names the DSN with its password masked: t/53-dbi-to-conninfo.t.)
#   2. an AccessBroker's answer the transport cannot connect from is refused
#      the same way -- and what stands between 'dbi:' and the next ':' of a
#      DSN is not only a driver name: DBI reads attributes there, Password
#      among them;
#   3. a conninfo libpq cannot read makes EV::Pg->new die with libpq's words,
#      and libpq quotes a postgresql:// URI whole, user:password@ included.
#      That reaches the caller of a pooled statement and of listen;
#   4. what EV::Pg reports through on_error for a connection is libpq's text
#      too. It goes to the pool's Future, the pool's warning and the listen
#      connection's error unchanged otherwise, so it is masked where the handle
#      is made -- for the pool's connections and the listen connection alike.
#
# The claim each time: the password is not in the message, and the rest is --
# a message that says nothing would hide the password as well.
#
# WHAT RUNS FOR REAL: everything -- core's storage, pool and broker seams,
# this dist's Storage, Pool and ConnectInfo, EV::Pg and libpq's conninfo
# parser. Nothing is connected: libpq refuses the conninfo of section 3 before
# it opens a socket, and the handles of section 4 are given no conninfo at all.

use EV;
use EV::Pg;
use DBIO::AccessBroker;
use DBIO::PostgreSQL::EV::Storage;
use DBIO::PostgreSQL::EV::Pool;

alarm 60;

my $EV     = 'DBIO::PostgreSQL::EV::Storage';
my $SECRET = 'hunter2';

# A refusal of the transport's own is a DBIO::Exception since karr k88
# (maintainer's decision 2026-10-16): core's origin -- the transport's method
# that refused -- stands in front of the words, the caller's place behind
# them. Until then the words began the message.
my $ORIGIN = qr/DBIO::PostgreSQL::EV::Storage::\w+\(\): /;

# A broker answering whatever the test puts in it.
{
  package AnswerBroker;
  use base 'DBIO::AccessBroker';
  sub new { my ($class, $answer) = @_; bless { answer => $answer }, $class }
  sub connect_info_for { $_[0]{answer} }
}

{
  package PlainSchema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('PostgreSQL');
}

# How a pool spawn and a listen open end on this storage: the error of each,
# and the pool's warnings.
sub connection_errors {
  my ($s) = @_;
  my (%err, @warned);
  local $SIG{__WARN__} = sub { push @warned, @_ };
  $err{pool} = eval {
    my $f = $s->pool->acquire;
    $f->is_failed ? ($f->failure)[0] : 'no error';
  } // $@;
  $err{listen} = eval { $s->_listen_open; 'no error' } // $@;
  $err{warned} = join '', @warned;
  return \%err;
}

# ---------------------------------------------------------------------------
# 1. Connect info the transport cannot connect from.
# ---------------------------------------------------------------------------

# Every form connect_info refuses, with the password wherever that form can
# hold one: [ label, connect info, what the message names ].
my @UNREADABLE = (
  [ 'the DBI form for another driver, the password in the DSN and beside it',
    [ "dbi:mysql:database=appdb;password=$SECRET", 'app', $SECRET, { Password => $SECRET } ],
    qr/a DBI-form arrayref whose DSN is not dbi:Pg:<parameters> \(DBI driver 'mysql'\)/ ],
  [ q{DBI's Password attribute in front of the driver's name, no colon (nothing behind dbi:Pg: is read since k66)},
    [ "dbi:Pg(Username=>app,Password=>$SECRET)", undef, undef, {} ],
    qr/a DBI-form arrayref whose DSN is not dbi:Pg:<parameters> \(DBI driver 'Pg'\)/ ],
  [ 'a DSN with no colon behind the driver before its password',
    [ "dbi:Pg;dbname=appdb;password=$SECRET;host=[::1]", 'app', undef, {} ],
    qr/a DBI-form arrayref whose DSN is not dbi:Pg:<parameters> \(DBI driver 'Pg'\)/ ],
  [ 'a dbi:Pg: DSN libpq cannot read, its password in two words',
    [ "dbi:Pg:dbname=appdb;password=$SECRET $SECRET", 'app', undef ],
    qr/a DBI-form arrayref -- the dbi:Pg: DSN cannot be read as libpq parameters: missing "=" after a parameter name/ ],
  [ 'a hash with another driver\'s DSN for its dsn',
    [ { dsn => "dbi:mysql:database=appdb;password=$SECRET", user => 'app', password => $SECRET } ],
    qr/a hashref with a dsn key whose DSN is not dbi:Pg:<parameters> \(DBI driver 'mysql'\)/ ],
  [ 'a hash whose dsn is a libpq conninfo string',
    [ { dsn => "host=db.example password=$SECRET", password => $SECRET } ],
    qr/a hashref with a dsn key whose DSN is not dbi:Pg:<parameters>\./ ],
  [ 'a hash whose dbname is a DSN, with a host beside it',
    [ { dbname => "dbi:Pg:dbname=appdb;password=$SECRET", host => 'db.example', password => $SECRET } ],
    qr/a hashref whose dbname is a whole DSN, with host beside it/ ],
  [ 'a hash with a dbh_maker',
    [ { dbh_maker => sub { die "never called\n" }, password => $SECRET } ],
    qr/a code reference that makes a DBI handle \(dbh_maker\)/ ],
  [ 'a code reference, attributes behind it',
    [ sub { die "never called\n" }, { Password => $SECRET } ],
    qr/a code reference that makes a DBI handle --/ ],
  [ 'a hash with a reference for a parameter',
    [ { host => [ 'db.example' ], password => $SECRET } ],
    qr/its libpq connection parameter 'host' is a reference, not a value/ ],
  [ 'a libpq conninfo string with a user and a password beside it',
    [ "host=db.example password=$SECRET", 'app', $SECRET ],
    qr/an arrayref of \(string, string, string\)/ ],
  [ 'the DBI form inside another array',
    [ [ "dbi:Pg:dbname=appdb;password=$SECRET", 'app', $SECRET ], {} ],
    qr/an arrayref of \(ARRAY ref, HASH ref\)/ ],
  [ 'a libpq conninfo string that stands in no array',
    "host=db.example password=$SECRET",
    qr/a plain string/ ],
  [ 'a hash that stands in no array',
    { host => 'db.example', password => $SECRET },
    qr/a hashref with keys \(host, password\)/ ],
);

for my $case (@UNREADABLE) {
  my ($label, $info, $named_re) = @$case;

  my $ok  = eval { $EV->new(undef)->connect_info($info); 1 };
  my $err = "$@";
  ok !$ok, "$label: connect_info refuses it";
  like $err, qr/^$ORIGIN\QPostgreSQL ev cannot connect from this connect info: \E/, '... saying that it cannot connect from it';
  like $err, $named_re, '... naming its form';
  unlike $err, qr/\Q$SECRET\E/, '... never the password';
}

{
  # Through a schema the transport is built at the first ->async, and that is
  # where it refuses. DBI takes attributes in front of a DSN's parameters;
  # without the colon behind them there is no DSN, and this transport does not
  # read it (a DSN with nothing behind its colon is read since karr k66).
  my $schema = PlainSchema->connect("dbi:Pg(Password=>$SECRET)", 'app', undef, { async => 'ev' });
  my $async  = eval { $schema->storage->async };
  my $err    = "$@";
  ok !$async, 'a DSN the transport does not read, through a schema: the first ->async refuses it';
  like $err, qr/a DBI-form arrayref whose DSN is not dbi:Pg:<parameters> \(DBI driver 'Pg'\)/,
    '... naming the form and the DBI driver';
  unlike $err, qr/\Q$SECRET\E/, '... without the password in the DSN';
}

# ---------------------------------------------------------------------------
# 2. A broker's answer the transport cannot connect from.
# ---------------------------------------------------------------------------

# The same forms as a broker answers them -- a hash on its own, an array as
# it is; what is no array and no hash is section 1's only -- read by the same
# reader, with the same words for the form.
for my $case (grep { ref $_->[1] eq 'ARRAY' } @UNREADABLE) {
  my ($label, $info, $named_re) = @$case;
  my $answer = @$info == 1 && ref $info->[0] eq 'HASH' ? $info->[0] : $info;

  my $ok  = eval { $EV->new(undef)->connect_info([ AnswerBroker->new($answer) ]); 1 };
  my $err = "$@";
  ok !$ok, "a broker answering $label: attaching it croaks";
  like $err, qr/^$ORIGIN\QPostgreSQL ev cannot connect from what the AccessBroker returned: \E/,
    '... saying that it cannot connect from the answer';
  like $err, $named_re, '... naming its form';
  unlike $err, qr/\Q$SECRET\E/, '... never the password';
}

for my $case (
  [ q{DBI's Password attribute in front of the driver's name, no colon (nothing behind dbi:Pg: is read since k66)},
    [ "dbi:Pg(Username=>app,Password=>$SECRET)", undef, undef, {} ],
    qr/\(DBI driver 'Pg'\)/ ],
  [ 'a DSN with no colon behind the driver before its password',
    [ "dbi:Pg;dbname=appdb;password=$SECRET;host=[::1]", 'app', undef, {} ],
    qr/\(DBI driver 'Pg'\)/ ],
  [ 'another driver',
    [ "dbi:mysql:database=appdb;password=$SECRET", 'app', $SECRET, {} ],
    qr/\(DBI driver 'mysql'\)/ ],
) {
  my ($label, $answer, $driver_re) = @$case;

  my $ok  = eval { $EV->new(undef)->connect_info([ AnswerBroker->new($answer) ]); 1 };
  my $err = $@;
  ok !$ok, "a broker answering $label: attaching it croaks";
  like $err, qr/a DBI-form arrayref whose DSN is not dbi:Pg:<parameters>/, '... naming the shape';
  like $err, $driver_re, '... and the DBI driver';
  unlike $err, qr/\Q$SECRET\E/, '... never the password';
}

# ---------------------------------------------------------------------------
# 3. A conninfo libpq cannot read.
# ---------------------------------------------------------------------------

{
  # The bracket of the IPv6 host is never closed. libpq: 'end of string
  # reached when looking for matching "]" in IPv6 host address in URI: "..."'.
  my $uri = "postgresql://app:$SECRET\@[::1/appdb";

  ok !eval { EV::Pg->new(conninfo => $uri, on_error => sub { }); 1 },
    'libpq refuses a postgresql:// URI with an IPv6 host that is not closed';
  like $@, qr/\Q$SECRET\E/, '... quoting the URI, its password included: what must not be passed on';

  for my $case (
    [ 'static connect info', [ $uri ] ],
    [ 'a broker\'s answer',  [ AnswerBroker->new([ $uri ]) ] ],
  ) {
    my ($label, $info) = @$case;
    my $s = $EV->new(undef);
    ok eval { $s->connect_info($info); 1 }, "that URI as $label: it is taken, libpq has not read it yet"
      or diag $@;

    my $err = connection_errors($s);
    for my $what (qw( pool listen )) {
      like $err->{$what}, qr/IPv6 host address in URI/, "$label, $what: opening a connection fails with libpq's words";
      unlike $err->{$what}, qr/\Q$SECRET\E/, '... without the password';
      like $err->{$what}, qr{postgresql://app:\*\*\*\@\[::1/appdb}, '... and with the rest of the URI';
    }
    unlike $err->{warned}, qr/\Q$SECRET\E/, "$label: no warning carries it either";
  }
}

# ---------------------------------------------------------------------------
# 4. What EV::Pg reports through on_error.
# ---------------------------------------------------------------------------

{
  # A handle without a conninfo connects nowhere; its on_error is called by
  # hand, with a message quoting a conninfo the way libpq's parser does.
  my $text = qq{could not open the connection from "host=db.example user=app password=$SECRET sslmode=require"};
  my $want = qq{could not open the connection from "host=db.example user=app password=*** sslmode=require"};

  my @listen_got;
  my $listen_pg = DBIO::PostgreSQL::EV::Pool->_new_connection(on_error => sub { push @listen_got, @_ });
  $listen_pg->on_error->($text);
  is_deeply \@listen_got, [ $want ],
    'the listen connection\'s handle: its on_error gets libpq\'s text with the password masked';
  $listen_pg->finish;

  my (@pool_got, @ready_got);
  my $pool = DBIO::PostgreSQL::EV::Pool->new(
    conninfo => 'never used', size => 1, on_error => sub { push @pool_got, @_ },
  );
  my $pool_pg = $pool->_new_connection(on_error => sub { push @ready_got, @_ });
  $pool_pg->on_error->($text);
  is_deeply \@ready_got, [ $want ], 'a pooled handle: the same, for what core fails the connection\'s Future with';
  $pool_pg->finish;
  $pool->shutdown;

  # Nothing to mask: the text is handed on as it came.
  my @plain;
  my $pg = DBIO::PostgreSQL::EV::Pool->_new_connection(on_error => sub { push @plain, @_ });
  $pg->on_error->(qq{connection to server at "db.example", port 5432 failed: FATAL:  database "appdb" does not exist\n});
  is_deeply \@plain,
    [ qq{connection to server at "db.example", port 5432 failed: FATAL:  database "appdb" does not exist\n} ],
    'a message without a password is handed on unchanged';
  $pg->finish;
}

done_testing;
