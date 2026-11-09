use strict;
use warnings;
use Test::More;

# LIVE: a connection parameter given beside an AccessBroker, against a real
# server (karr k78). The offline half,
# t/39-access-broker-parameters-beside-mock.t, pins the refusal, its measure
# and what is left of a storage after it. This file asks the SERVER what was
# opened, and when:
#
#   MyApp::Schema->connect($broker, { async => 'ev', charset => 'latin1' })
#
# WHY it matters: the parameter beside the broker was dropped, so the pool
# connected without it and the application ran. Refusing is only better if the
# refusal is complete -- no session of the transport exists that was opened
# without the parameter -- and if what the refusal tells the caller to do
# instead does reach a connection. Neither can be seen without a server.
#
# The parameter is charset, because the server shows it: a session opened
# with charset => 'latin1' has @@character_set_client = latin1, one opened
# without it has the client library's default. The sessions of a case are the
# ones the server lists for the test user that were not there before it.
#
#   a) charset beside a broker, through a schema:
#      - Schema->connect goes through, and the server has no session for it;
#      - the first ->async is refused, naming charset and neither its value
#        nor the password, and again when asked again; a statement on the
#        async API is refused the same way; the server still has no session;
#      - the owning sync storage, which is core's: it refuses the parameter on
#        its own account when its dbh is asked for (core k307), so no session
#        of the schema is opened without the parameter at all;
#   b) the transport addressed directly, [ $broker, { charset => ... } ] and
#      [ $broker, { host => ... } ]: refused when given the connect info, a
#      pool connection asked for afterwards fails for the same reason, and the
#      server has no session for it;
#   c) the control: the same broker with a DBD attribute and pool_size beside
#      it and no parameter is connected and a pooled statement runs, in the
#      default character set -- the refusal is about the parameter;
#   d) what the refusal says to do instead: the parameter in the broker's
#      answer. As a hash answered to this transport (connect_info_for_storage)
#      through a schema, and as the DBI form with the parameter in the DSN
#      given to the transport: the pooled session is opened WITH it.
#
# Gated like the other live tests: DBIO_TEST_MYSQL_DSN (dbi:mysql: or
# dbi:MariaDB:), _USER, _PASS, plus EV and EV::MariaDB. The DSN, the user and
# the password are never printed.

use DBIO::MySQL::EV::TestHarness;

DBIO::MySQL::EV::TestHarness->skip_all_unless_live;

my ($DSN, $USER, $PASS) = map { $ENV{"DBIO_TEST_MYSQL_$_"} } qw( DSN USER PASS );
plan skip_all => 'Set DBIO_TEST_MYSQL_USER and DBIO_TEST_MYSQL_PASS: the broker hands out credentials'
  unless defined $USER && length $USER && defined $PASS && length $PASS;

use EV;
use EV::MariaDB;
use DBI;
use Scalar::Util ();
use Future;
use DBIO::AccessBroker;
use DBIO::MySQL::EV::ConnectInfo ();
use DBIO::MySQL::EV::Storage;
use DBIO::Util ();

# Every wait below is bounded by a timer of its own.
$SIG{ALRM} = sub { BAIL_OUT('t/39-access-broker-parameters-beside-live.t: alarm, a wait did not end') };
alarm 120;

my $EV = 'DBIO::MySQL::EV::Storage';

# The DSN's parts, as this transport reads a DBI DSN everywhere else.
my $parts = eval { DBIO::MySQL::EV::ConnectInfo::dbi_to_conninfo([ $DSN ])->[0] }
  or plan skip_all => 'DBIO_TEST_MYSQL_DSN is not a dbi:mysql: / dbi:MariaDB: DSN';
plan skip_all => 'the test DSN sets a charset of its own; this file tells its sessions apart by it'
  if exists $parts->{charset};

# The server's view, from a connection that belongs to no case.
my $observer = do {
  # DBI dies quoting the DSN: named without a password it may carry.
  eval { DBI->connect($DSN, $USER, $PASS, { RaiseError => 1, PrintError => 0, AutoCommit => 1 }) }
    or die DBIO::Util::mask_connect_secrets("$@", [ $DSN, $USER, $PASS ]);
};
my ($observer_id) = $observer->selectrow_array('SELECT CONNECTION_ID()');

# What is asked of a session: which one it is, and its character set.
my $WHICH = 'SELECT CONNECTION_ID(), @@character_set_client';

# The parameter's value: a character set that is not the default of a session
# opened without one.
my $CHARSET = 'latin1';

sub wait_for {
  my ($f, $seconds) = @_;
  my $late  = 0;
  my $timer = EV::timer($seconds, 0, sub { $late = 1 });
  EV::run(EV::RUN_ONCE) until $f->is_ready || $late;
  return $f->is_ready;
}

# Let the loop turn for a moment: what a connection in the making would need
# to arrive at the server.
sub settle {
  my $done  = 0;
  my $timer = EV::timer(0.3, 0, sub { $done = 1 });
  EV::run(EV::RUN_ONCE) until $done;
  return;
}

# An error on one line, without the places it was raised at.
sub bare {
  my ($err) = @_;
  $err = "$err";
  $err =~ s{ at \S+ line \d+\.?}{}g;
  $err =~ s{\s*\n\s*\.?\s*}{ | }g;
  $err =~ s{[\s|]+\z}{};
  return $err;
}

# Every handle this process opens from here on -- an EV::MariaDB one of a pool
# or the listen slot, a DBI one of an owning sync storage -- is noted, whatever
# slot it ends up in, so a connection leaked outside them is counted as well.
# The process list of the user also holds the sessions of whoever else talks
# to the server at the time; those are not ours to count.
my (@handles, %own);
{
  no warnings 'redefine';
  my $mdb_new = \&EV::MariaDB::new;
  *EV::MariaDB::new = sub {
    my $mdb = $mdb_new->(@_);
    if (ref $mdb) { push @handles, $mdb; Scalar::Util::weaken($handles[-1]) }
    return $mdb;
  };
  my $connect = \&DBI::connect;
  *DBI::connect = sub {
    my $dbh = $connect->(@_);
    $own{ $dbh->{mariadb_thread_id} // $dbh->{mysql_thread_id} } = 1 if ref $dbh;
    return $dbh;
  };
}

# The sessions of this test's own handles that the server still lists, the
# observer left out. A handle's session id is read while the handle lives: its
# disconnect ends the session.
sub sessions {
  for my $mdb (grep { defined } @handles) {
    my $id = eval { $mdb->thread_id } or next;
    $own{$id} = 1;
  }
  delete $own{$observer_id};
  return {} unless %own;
  return { map { $_->[0] => 1 } @{ $observer->selectall_arrayref(
    'SELECT id FROM information_schema.processlist WHERE id IN (' . join(',', ('?') x keys %own) . ')',
    undef, keys %own,
  ) } };
}

# The sessions that were not there at $before, after what a connect would need.
sub opened_since {
  my ($before) = @_;
  settle();
  return [ sort { $a <=> $b } grep { !$before->{$_} } keys %{ sessions() } ];
}

# One pooled connection of $storage: the row of $WHICH, or an error. The
# connection is given back.
sub pooled_which {
  my ($storage) = @_;
  my $acquire = eval { $storage->pool->acquire } // Future->fail(bare($@));
  return (undef, 'the acquire was not answered within 30s') unless wait_for($acquire, 30);
  return (undef, bare(($acquire->failure)[0])) if $acquire->is_failed;

  my $conn  = $acquire->get;
  my $asked = Future->new;
  $conn->query($WHICH, sub { $_[1] ? $asked->fail($_[1]) : $asked->done($_[0][0]) });
  wait_for($asked, 30);
  $storage->pool->release($conn);
  return ($asked->get) if $asked->is_done;
  return (undef, $asked->is_ready ? bare($asked->failure) : 'not answered within 30s');
}

# A broker answering whatever the test puts in it: here the DBI form, which
# both halves of a schema connect from.
{
  package T39L::AnswerBroker;
  use base 'DBIO::AccessBroker';
  sub new { my ($class, $answer) = @_; bless { answer => $answer }, $class }
  sub connect_info_for { $_[0]{answer} }
}

# A broker answering by the storage that asks: this transport its own shape,
# every other storage the DBI form.
{
  package T39L::ByStorageBroker;
  use base 'DBIO::AccessBroker';
  sub new { my ($class, %answer) = @_; bless { %answer }, $class }
  sub connect_info_for_storage {
    my ($self, $storage) = @_;
    return $storage->isa('DBIO::MySQL::EV::Storage') ? $self->{ev} : $self->{dbi};
  }
}

{
  package T39L::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('MySQL');
}

sub broker { T39L::AnswerBroker->new([ $DSN, $USER, $PASS ]) }

my $REFUSED = qr/MySQL ev does not apply connection parameter\(s\) given beside an AccessBroker/;

# A refusal naming $name, and neither the value beside the broker nor the
# password. A value that is a common word says nothing when it turns up in a
# sentence, so the values here are chosen not to be in the message.
sub is_refused {
  my ($err, $name, $value, $when) = @_;
  $err = bare($err // '');
  like $err, qr/$REFUSED \(\Q$name\E\)/, "$when: refused, naming $name";
  ok index($err, $value) < 0 && (length $PASS < 4 || index($err, $PASS) < 0),
    '... and neither its value nor the password';
  return;
}

my (@schemas, @storages);
END {
  eval { $_->disconnect } for grep { $_ } @storages;
  eval { $_->storage->disconnect } for grep { $_ } @schemas;
}

# What a session opened without the parameter looks like.
my $default_charset;

subtest 'c) control: a DBD attribute and pool_size beside the broker, no parameter' => sub {
  my $before = sessions();
  # An attribute of the DBD the DSN names, and one of DBI's own.
  my $dbd    = $DSN =~ /^dbi:mariadb:/i ? 'mariadb' : 'mysql';
  my $schema = T39L::Schema->connect(broker(), {
    async => 'ev', pool_size => 2, "${dbd}_auto_reconnect" => 0, RaiseError => 1,
  });
  push @schemas, $schema;
  my $async = eval { $schema->storage->async };
  isa_ok $async, $EV, 'the transport' or diag bare($@);
  return unless $async;
  push @storages, $async;

  my ($which, $err) = pooled_which($async);
  ok $which, 'a pooled statement runs' or diag $err;
  $default_charset = $which && $which->[1];
  isnt $default_charset, $CHARSET, "... in the default character set, which is not $CHARSET"
    or BAIL_OUT("the default character set of a session is $CHARSET: this file cannot tell its sessions apart");
  is_deeply opened_since($before), [ $which ? $which->[0] : () ], '... on the one session of the case';
  eval { $async->disconnect };
};

subtest 'a) charset beside a broker, through a schema' => sub {
  my $before = sessions();
  my $schema = eval { T39L::Schema->connect(broker(), { async => 'ev', charset => $CHARSET }) };
  ok $schema, 'Schema->connect goes through: the transport is not built yet' or diag bare($@);
  return unless $schema;
  push @schemas, $schema;
  my $storage = $schema->storage;

  is_deeply opened_since($before), [], '... and the server has no session for it';

  for my $ask ('the first ->async', '->async again') {
    my $async = eval { $storage->async };
    my $err   = $@;
    ok !$async, "$ask: no transport is handed out";
    is_refused($err, 'charset', $CHARSET, $ask);
    push @storages, $async if $async;
  }
  my $f   = eval { $storage->select_async(\'(SELECT 1 AS one) me', [ 'one' ]) };
  my $err = !$f ? $@ : wait_for($f, 30) ? ($f->is_failed ? ($f->failure)[0] : 'it ran') : 'it did not settle';
  is_refused($err, 'charset', $CHARSET, 'a statement on the async API');
  is_deeply opened_since($before), [], 'the server still has no session: the refusal opened nothing';

  # The owning sync storage is core's. It refuses the parameter on its own
  # account, when it is about to open its dbh (core k307): held here because
  # this distribution's POD says so, and because it is what makes the refusal
  # complete for a schema -- no session at all without the parameter.
  my $dbh = eval { $storage->dbh };
  $err    = bare($@);
  ok !$dbh, 'the owner\'s dbh is not opened either';
  like $err, qr/does not apply parameter\(s\) given beside AccessBroker \S+ \(charset\)/,
    '... core refuses the parameter beside the broker, naming it';
  is_deeply opened_since($before), [], '... and the server has no session for the schema at all';
};

subtest 'b) the transport addressed directly' => sub {
  for my $case (
    [ 'charset', $CHARSET ],
    # Dropped before k78, this left the pool connecting to the broker's host
    # while another one stood beside it.
    [ 'host', 'elsewhere.invalid' ],
  ) {
    my ($name, $value) = @$case;
    my $before = sessions();

    my $s   = $EV->new(undef);
    my $ok  = eval { $s->connect_info([ broker(), { $name => $value } ]); 1 };
    my $err = $@;
    push @storages, $s;
    ok !$ok, "[ \$broker, { $name => ... } ] is refused";
    is_refused($err, $name, $value, "$name beside the broker");

    my $f = eval { $s->pool->acquire } // Future->fail($@);
    wait_for($f, 30);
    is_refused($f->is_failed ? ($f->failure)[0] : 'a connection was handed out', $name, $value,
      'a pool connection asked for afterwards');
    is_deeply opened_since($before), [], '... and the server has no session for it';
  }
};

subtest 'd) the parameter in the broker\'s answer' => sub {
  plan skip_all => 'the control did not show the default character set' unless defined $default_charset;

  # Answered to this transport as a hash of EV::MariaDB parameters, to the
  # owning sync storage as the DBI form.
  {
    my $before = sessions();
    my %hash   = (
      ( map { ($_ eq 'database' ? 'dbname' : $_) => $parts->{$_} } keys %$parts ),
      user => $USER, password => $PASS, charset => $CHARSET,
    );
    my $schema = T39L::Schema->connect(
      T39L::ByStorageBroker->new(ev => \%hash, dbi => [ $DSN, $USER, $PASS ]),
      { async => 'ev', pool_size => 1 },
    );
    push @schemas, $schema;
    my $async = eval { $schema->storage->async };
    isa_ok $async, $EV, 'a broker answering by the storage that asks: the transport' or diag bare($@);

    SKIP: {
      skip 'no transport', 3 unless $async;
      push @storages, $async;
      my ($which, $err) = pooled_which($async);
      is $which && $which->[1], $CHARSET, "... its pooled session is opened with charset $CHARSET"
        or diag $err // 'it has another';
      my ($owner_charset) = eval { $schema->storage->dbh->selectrow_array('SELECT @@character_set_client') };
      ok defined $owner_charset, '... the owner\'s dbh connects from its own answer' or diag bare($@);
      is scalar @{ opened_since($before) }, 2, '... and the case has those two sessions';
      eval { $async->disconnect };
    }
  }

  # The DBI form with the parameter in the DSN, given to the transport.
  {
    my $s  = $EV->new(undef);
    my $ok = eval { $s->connect_info([ T39L::AnswerBroker->new([ "$DSN;charset=$CHARSET", $USER, $PASS ]) ]); 1 };
    push @storages, $s;
    ok $ok, 'a broker answering the DBI form with charset in the DSN: the transport takes it' or diag bare($@);
    my ($which, $err) = pooled_which($s);
    is $which && $which->[1], $CHARSET, "... and its pooled session is opened with charset $CHARSET"
      or diag $err // 'it has another';
    eval { $s->disconnect };
  }
};

$observer->disconnect;

done_testing;
