use strict;
use warnings;
use Test::More;

# OFFLINE test: every built-in AccessBroker on the ev transport (karr k54,
# found in dbio-postgresql k80).
#
# WHY: every connection this transport opens -- each pool spawn, and the
# dedicated listen connection at its open and at every reconnect -- is
# EV::Pg->new(conninfo => $string), and $string is rendered from what
# _async_broker_conninfo made of the broker's answer. That seam handed the
# answer straight to core's pair splitter, which takes its first element. A
# Static broker answers a libpq hash, so it worked; a Vault broker answers the
# DBI form [ 'dbi:Pg:...', $user, $password, \%attrs ], so libpq got the bare
# DSN string -- which it refuses ('dbi:Pg:dbname' is no connection option) --
# and the user and password were never read. HostBound over either alike.
#
# What this file claims:
#   1. for each built-in broker shape -- Static, Vault, HostBound over Static,
#      HostBound over Vault -- a pool connection and the listen connection are
#      both opened with exactly the libpq parameters the broker's answer means:
#      its dbname / host / port and its current user and password, and nothing
#      else -- no DSN string, no DBIO-private attribute (async), no DBD
#      attribute (pg_enable_utf8);
#   2. the broker is asked again for every connection: credentials that rotate
#      between two spawns reach the second one, and the listen connection
#      opened after them;
#   3. the transport's own shapes still pass: a libpq hash with any libpq
#      parameter (values libpq would misread come back intact), the pair
#      [ \%conninfo, \%opts ], a libpq conninfo string in an arrayref; a
#      pool_size in the answer sizes the pool and never reaches libpq;
#   4. an answer the transport cannot connect from croaks -- at attach, and at
#      a later spawn or listen open when the broker's answer turns bad --
#      naming its shape and never the password in it, and nothing reaches
#      EV::Pg. An answer of nothing (undef, an empty hash or array) is among
#      them: an empty hash renders to the empty conninfo, which libpq fills
#      from its environment and defaults -- a connection to whatever PGHOST
#      and PGUSER name. Core refuses an answer of nothing before the transport
#      reads it, naming the broker class (core k250, karr k62). Core cannot
#      know what a transport renders, though: an answer that is not nothing to
#      core -- a pair around an empty hash, a hash with nothing but pool_size,
#      a hash whose only parameter is undefined, a blank conninfo string, a
#      DSN without a parameter -- still renders to the empty conninfo. The
#      transport refuses every answer that renders to one, whatever its shape,
#      where it reads the answer (karr k61);
#   5. the schema path: MyApp::Schema->connect($vault) with
#      dbi_attrs => { async => 'ev' } -- the way a DBI-form broker picks the
#      mode -- reaches this transport and connects from the broker;
#   6. there is one reading path: attach, every pool spawn and every listen
#      open read the broker's answer through core's seam
#      _current_async_connect_info, so what holds at that seam holds for all
#      three and not for the attach alone (karr k61);
#   7. a broker detached behind the transport's back leaves nothing to connect
#      from: the per-spawn provider is still in place then, and it refuses
#      saying that no broker is attached -- no pool spawn or listen open is
#      made from what that seam answers without a broker, and none blames a
#      broker for an answer nobody gave (karr k61);
#   8. no conninfo is kept from a broker's answer (karr k63, core k252). With
#      a broker attached nothing reads a stored one -- every connection asks
#      the broker again -- so a copy could only be the FIRST answer, password
#      included: lying in the storage object for a dump or a log to find, and
#      what the storage connects from once the broker and its provider are
#      gone -- a Vault lease long rotated out, or the password of a Static
#      broker that was taken away on purpose. A storage whose broker is gone
#      has nothing to connect from, like one never given connect info. Static
#      connect info is still stored, and going from a broker to static connect
#      info and back leaves what belongs to each;
#   9. that holds when attaching the broker THROWS (karr k67, core k265).
#      connect_info attached the broker, read its answer, and only then dropped
#      the conninfo the connect_info before had stored. Everything in between
#      can throw -- the broker itself, core's refusal of an answer of nothing,
#      this transport's refusal of an answer it cannot connect from, two pool
#      sizes that disagree -- and when it did, the storage was left with the
#      broker attached and the STATIC conninfo of its previous connection
#      still stored. Nothing reads that while the broker is attached. Detach
#      it, and the next connection was opened from it: the identity the caller
#      had just replaced. For every way the attach can throw: the static
#      conninfo is gone from the storage object; with the broker still
#      attached a connection asks IT; with the broker detached -- either way
#      -- nothing is opened from the static connect info.
#
# WHAT RUNS FOR REAL: the built-in brokers, core's broker attach and per-spawn
# provider, core's pool and listen machinery, this dist's Pool and Storage.
# THE SUBSTITUTIONS: EV::Pg records what it is constructed with (the test plays
# the server's connect); the Vault client is a stub whose secret the test sets.

BEGIN {
  package EV::Pg;
  use Scalar::Util ();

  our @NEW;   # every EV::Pg->new: [ conninfo, the handle (weak) ]

  sub new {
    my ($class, %args) = @_;
    my $self = bless { args => { %args }, connected => 0 }, $class;
    # connect_timeout=10 is the transport's own default (karr k101, t/111): not part of what these tests compare
    push @NEW, [ $args{conninfo} =~ s/\s*connect_timeout=10\z//r, $self ];
    Scalar::Util::weaken($NEW[-1][1]);
    return $self;
  }

  for my $h (qw( on_connect on_error on_notify )) {
    no strict 'refs';
    *{"EV::Pg::$h"} = sub { my $s = shift; $s->{args}{$h} = $_[0] if @_; $s->{args}{$h} };
  }

  sub is_connected { $_[0]{connected} ? 1 : 0 }
  sub socket       { -1 }
  sub finish       { $_[0]{connected} = 0; return }

  # The server's side: the connect completes.
  sub t_connect {
    my ($s) = @_;
    $s->{connected} = 1;
    $s->{args}{on_connect}->() if $s->{args}{on_connect};
    return;
  }

  $INC{'EV/Pg.pm'} = __FILE__;
}

use EV;
use DBIO::AccessBroker::Static;
use DBIO::AccessBroker::Vault;
use DBIO::AccessBroker::HostBound;
use DBIO::PostgreSQL::EV::Storage;

plan skip_all => 'the installed DBIO core predates the LISTEN/NOTIFY contract (core k219)'
  unless DBIO::Storage::Async->can('listen_alive');

alarm 60;

# A libpq conninfo string back into its parameters: key=value or
# key='quoted value' with \' and \\ escaped -- the syntax libpq reads. Dies on
# anything else, so a DSN string or a rendering libpq would misread is caught.
sub parse_conninfo {
  my ($str) = @_;
  die "no conninfo string\n" unless defined $str && !ref $str;
  my %h;
  pos($str) = 0;
  while ($str =~ /\G\s*([A-Za-z_]+)=(?:'((?:[^'\\]|\\.)*)'|([^\s']*))/gc) {
    my ($key, $quoted, $bare) = ($1, $2, $3);
    die "conninfo names '$key' twice\n" if exists $h{$key};
    $h{$key} = defined $quoted ? $quoted =~ s/\\(.)/$1/gr : $bare;
  }
  die "not a libpq conninfo string\n" unless $str =~ /\G\s*\z/gc;
  return \%h;
}

# The Vault client: read_secret answers whatever the test last put in it.
{
  package FakeVaultClient;
  sub new { bless { secret => { username => 'vault-user-1', password => 'vault-pw-1' }, reads => 0 }, shift }
  sub read_secret { my ($self) = @_; $self->{reads}++; return { %{ $self->{secret} } } }
}

# A broker answering whatever the test puts in it.
{
  package AnswerBroker;
  use base 'DBIO::AccessBroker';
  sub new { my ($class, $answer) = @_; bless { answer => $answer }, $class }
  sub connect_info_for { $_[0]{answer} }
}

sub transport_with {
  my ($broker) = @_;
  my $s = DBIO::PostgreSQL::EV::Storage->new(undef);
  $s->connect_info([ $broker ]);
  return $s;
}

# One new pool connection: what EV::Pg was constructed with. The connection is
# acquired and kept, so the next spawn is a new one.
sub spawn_conninfo {
  my ($s) = @_;
  @EV::Pg::NEW = ();
  my $f = $s->pool->acquire;
  die "acquire failed: " . ($f->failure)[0] if $f->is_failed;
  die scalar(@EV::Pg::NEW) . " EV::Pg handles made for one spawn\n" unless @EV::Pg::NEW == 1;
  my ($conninfo, $pg) = @{ $EV::Pg::NEW[0] };
  $pg->t_connect;
  die "the spawned connection was not handed out\n" unless $f->is_done && $f->get == $pg;
  return $conninfo;
}

# One open of the listen connection: what EV::Pg was constructed with. The
# connection is closed again.
sub listen_conninfo {
  my ($s) = @_;
  @EV::Pg::NEW = ();
  my $f = $s->_listen_open;
  die scalar(@EV::Pg::NEW) . " EV::Pg handles made for one listen open\n" unless @EV::Pg::NEW == 1;
  my ($conninfo, $pg) = @{ $EV::Pg::NEW[0] };
  $pg->t_connect;
  $s->_listen_close($f->get);
  return $conninfo;
}

sub vault {
  my (%args) = @_;
  return DBIO::AccessBroker::Vault->new(
    vault     => FakeVaultClient->new,
    dsn       => 'dbi:Pg:dbname=appdb;host=db.example;port=5433',
    cred_path => 'database/creds/app',
    dbi_attrs => { pg_enable_utf8 => 1, async => 'ev' },
    %args,
  );
}

sub static {
  return DBIO::AccessBroker::Static->new(
    host     => 'db.example',
    port     => 5433,
    dbname   => 'appdb',
    username => 'app',
    password => 's3cret',
    @_,
  );
}

# ---------------------------------------------------------------------------
# 1. Each built-in broker shape, on a pool spawn and on the listen connection.
# ---------------------------------------------------------------------------

for my $case (
  [ 'Static',
    sub { static() },
    { dbname => 'appdb', host => 'db.example', port => 5433, user => 'app', password => 's3cret' } ],
  [ 'Vault',
    sub { vault() },
    { dbname => 'appdb', host => 'db.example', port => 5433,
      user => 'vault-user-1', password => 'vault-pw-1' } ],
  # The lease is who the connection is opened as, whatever the DSN says: DBD::Pg
  # puts the user and password beside a DSN behind the ones in it, and libpq
  # takes the later (karr k58). Read the other way round, a DSN naming a user
  # pinned every pooled connection to it while the dbh used the lease.
  [ 'Vault, its DSN naming a user and password of its own',
    sub { vault(dsn => 'dbi:Pg:dbname=appdb;host=db.example;port=5433;user=dsn-user;password=dsn-pw') },
    { dbname => 'appdb', host => 'db.example', port => 5433,
      user => 'vault-user-1', password => 'vault-pw-1' } ],
  # Whitespace separates parameters for libpq, a line break included. The
  # transport's own look at a broker's DSN stopped at the first line and took
  # the rest for no dbi:Pg: DSN at all.
  [ q{Vault, its DSN's parameters on lines of their own},
    sub { vault(dsn => "dbi:Pg:dbname=appdb\nhost=db.example\nport=5433") },
    { dbname => 'appdb', host => 'db.example', port => 5433,
      user => 'vault-user-1', password => 'vault-pw-1' } ],
  [ 'HostBound over Static',
    sub { static()->for_host({ host => 'replica.example', port => 6432 }) },
    { dbname => 'appdb', host => 'replica.example', port => 6432, user => 'app', password => 's3cret' } ],
  [ 'HostBound over Vault',
    sub { vault()->for_host({ host => 'replica.example', port => 6432 }) },
    { dbname => 'appdb', host => 'replica.example', port => 6432,
      user => 'vault-user-1', password => 'vault-pw-1' } ],
) {
  my ($label, $build, $want) = @$case;
  my $s = eval { transport_with($build->()) };
  ok $s, "$label: the broker attaches" or diag $@;
  next unless $s;

  my $pool = eval { parse_conninfo(spawn_conninfo($s)) };
  is_deeply $pool, $want,
    "$label: a pool connection is opened with the broker's dbname, host, port, user and password -- nothing else"
    or diag $@;

  my $listen = eval { parse_conninfo(listen_conninfo($s)) };
  is_deeply $listen, $want,
    "$label: the listen connection is opened with the same parameters"
    or diag $@;

  my $rendered = eval { parse_conninfo($s->_conninfo_string) };
  is_deeply $rendered, $want,
    "$label: _conninfo_string renders the broker's current answer the same way"
    or diag $@;
}

# ---------------------------------------------------------------------------
# 2. Rotation: the broker is asked for every connection, not once at attach.
# ---------------------------------------------------------------------------

for my $case (
  [ 'Vault',                sub { $_[0] } ],
  [ 'HostBound over Vault', sub { $_[0]->for_host('replica.example') } ],
) {
  my ($label, $wrap) = @$case;
  my $vault = vault();
  my $s = eval { transport_with($wrap->($vault)) };
  ok $s, "$label: the broker attaches" or diag $@;
  next unless $s;

  my $first = eval { parse_conninfo(spawn_conninfo($s)) } || {};
  is_deeply [ @$first{qw( user password )} ], [ 'vault-user-1', 'vault-pw-1' ],
    "$label: the first pool connection uses the credentials Vault issued"
    or diag $@;

  $vault->vault->{secret} = { username => 'vault-user-2', password => 'vault-pw-2' };
  $vault->_expires_at(0);   # the lease is up
  my $reads = $vault->vault->{reads};

  my $second = eval { parse_conninfo(spawn_conninfo($s)) } || {};
  is $vault->vault->{reads}, $reads + 1, "$label: the expired lease was renewed for the next spawn";
  is_deeply [ @$second{qw( user password )} ], [ 'vault-user-2', 'vault-pw-2' ],
    "$label: ... and the second pool connection uses the ROTATED credentials"
    or diag $@;

  my $listen = eval { parse_conninfo(listen_conninfo($s)) } || {};
  is_deeply [ @$listen{qw( user password )} ], [ 'vault-user-2', 'vault-pw-2' ],
    "$label: the listen connection opened after the rotation uses them too"
    or diag $@;
}

# ---------------------------------------------------------------------------
# 3. The transport's own shapes, and pool_size.
# ---------------------------------------------------------------------------

{
  my %params = (
    dbname           => q{it's my db},
    host             => 'db.example',
    sslmode          => 'require',
    connect_timeout  => 5,
    application_name => 'back\\slash',
    user             => 'app',
    password         => q{p w'd},
  );
  my $s = transport_with(AnswerBroker->new({ %params }));
  is_deeply eval { parse_conninfo(spawn_conninfo($s)) }, \%params,
    'a libpq hash: every parameter reaches libpq, and a value with a space, a quote '
  . 'or a backslash comes back intact'
    or diag $@;

  $s = transport_with(AnswerBroker->new([ { dbname => 'appdb', user => 'app', password => 'pw', pool_size => 3 }, {} ]));
  is_deeply eval { parse_conninfo(spawn_conninfo($s)) },
    { dbname => 'appdb', user => 'app', password => 'pw' },
    'a [ \\%conninfo, \\%opts ] pair is read by its hash; pool_size does not reach libpq'
    or diag $@;
  is $s->pool->max_size, 3, '... and sizes the pool';

  my $string = q{host=db.example dbname=appdb user=app password='p w'};
  $s = transport_with(AnswerBroker->new([ $string ]));
  is eval { spawn_conninfo($s) }, $string,
    'a libpq conninfo string in an arrayref reaches EV::Pg as it is'
    or diag $@;

  $s = transport_with(vault(dbi_attrs => { pool_size => 3, async => 'ev' }));
  is_deeply eval { parse_conninfo(spawn_conninfo($s)) },
    { dbname => 'appdb', host => 'db.example', port => 5433,
      user => 'vault-user-1', password => 'vault-pw-1' },
    'a DBI-form answer with pool_size among its attributes: pool_size does not reach libpq'
    or diag $@;
  is $s->pool->max_size, 3, '... and sizes the pool, as in DBI-form connect info';
}

# ---------------------------------------------------------------------------
# 4. An answer the transport cannot connect from.
# ---------------------------------------------------------------------------

# Who refuses, and how the refusal reads. A shape this transport cannot read
# is refused by the transport ($CANNOT). An answer of nothing never gets that
# far: DBIO::Storage::current_access_broker_connect_info refuses it for every
# storage and names the broker class ($NOTHING; core k250) -- the same refusal
# whether the transport asks that method or core's _current_async_connect_info.
# What core lets through and this transport would render to the empty conninfo
# is the transport's to refuse ($CANNOT, $EMPTY): libpq fills an empty conninfo
# from PGHOST, PGUSER and its defaults, so the connection would go wherever the
# process environment points, as whoever it names -- not where the broker said.
my $CANNOT  = qr/PostgreSQL ev cannot connect from what the AccessBroker returned/;
my $NOTHING = qr/AccessBroker AnswerBroker answered no connect info/;
my $EMPTY   = 'no libpq connection parameter with a value in';

for my $case (
  [ 'a libpq string with user and password beside it',
    [ 'host=db.example dbname=appdb password=hunter2', 'app', 'hunter2' ],
    $CANNOT, qr/an arrayref of \(string, string, string\)/ ],
  [ 'a DBI-form arrayref for another driver',
    [ 'dbi:mysql:database=appdb;password=hunter2', 'app', 'hunter2', {} ],
    $CANNOT, qr/a DBI-form arrayref whose DSN is not dbi:Pg:<parameters> \(DBI driver 'mysql'\)/ ],
  # A DSN libpq refuses, so the dbh never connects from it: the blank ends the
  # password and 'x' is a parameter without '='. Read as the password
  # 'hunter2 x' it was a connection nobody asked for (karr k58).
  [ 'a DBI-form arrayref whose DSN libpq cannot read',
    [ 'dbi:Pg:dbname=appdb;password=hunter2 x', 'app', undef, {} ],
    $CANNOT, qr/a DBI-form arrayref -- the dbi:Pg: DSN cannot be read as libpq parameters: missing "=" after a parameter name/ ],
  [ 'a plain string',
    'host=db.example password=hunter2',
    $CANNOT, qr/a plain string/ ],
  [ 'nothing',
    undef,
    $NOTHING, qr/answered no connect info \(undef\)/ ],
  [ 'an empty hash',
    {},
    $NOTHING, qr/answered no connect info \(an empty hashref\)/ ],
  [ 'an empty array',
    [],
    $NOTHING, qr/answered no connect info \(an empty arrayref\)/ ],
  [ 'a hash with a reference as a parameter',
    { dbname => 'appdb', host => [ 'a', 'b' ], password => 'hunter2' },
    $CANNOT, qr/its libpq connection parameter 'host' is a reference/ ],
  # Not nothing to core, and still the empty conninfo once rendered (karr k61).
  [ 'a pair around an empty hash',
    [ {}, {} ],
    $CANNOT, qr/$EMPTY an empty hashref/ ],
  [ 'an arrayref holding an empty hash',
    [ {} ],
    $CANNOT, qr/$EMPTY an empty hashref/ ],
  [ 'a hash with nothing but pool_size',
    { pool_size => 3 },
    $CANNOT, qr/$EMPTY a hashref with keys \(pool_size\)/ ],
  [ 'a hash whose only parameter is undefined',
    { dbname => undef },
    $CANNOT, qr/$EMPTY a hashref with keys \(dbname\)/ ],
  [ 'a blank libpq conninfo string',
    [ '   ' ],
    $CANNOT, qr/$EMPTY an arrayref of \(string\)/ ],
  # karr k95: a DSN that names no target is refused with the sync storage's words.
  [ 'a DBI-form arrayref whose DSN names no parameter',
    [ 'dbi:Pg:;', undef, undef, { pool_size => 3 } ],
    qr/names no dbname, host or port/, qr/PGHOST, PGDATABASE/ ],
) {
  my ($label, $answer, $refusal_re, $shape_re) = @$case;

  # At attach.
  @EV::Pg::NEW = ();
  my $s   = DBIO::PostgreSQL::EV::Storage->new(undef);
  my $ok  = eval { $s->connect_info([ AnswerBroker->new($answer) ]); 1 };
  my $err = $@;
  ok !$ok, "unusable answer ($label): attaching the broker croaks";
  like $err, $refusal_re, '... saying what it could not connect from';
  like $err, $shape_re, '... naming the shape it received';
  unlike $err, qr/hunter2/, '... and never the password';

  # Later: the broker answered well at attach, then turns bad.
  my $broker = AnswerBroker->new({ dbname => 'appdb', user => 'app', password => 'pw' });
  $s = transport_with($broker);
  $broker->{answer} = $answer;
  @EV::Pg::NEW = ();

  my $f = $s->pool->acquire;
  ok $f->is_failed, "unusable answer ($label) at a later spawn: acquire fails";
  my ($spawn_err) = $f->is_failed ? $f->failure : ('');
  like $spawn_err, $refusal_re, '... saying what it could not connect from';
  like $spawn_err, $shape_re, '... naming the shape';
  unlike $spawn_err, qr/hunter2/, '... and never the password';

  $ok  = eval { $s->_listen_open; 1 };
  $err = $@;
  ok !$ok, "unusable answer ($label) at a later listen open: it croaks";
  like $err, $refusal_re, '... saying what it could not connect from';
  like $err, $shape_re, '... naming the shape';
  unlike $err, qr/hunter2/, '... and never the password';

  is scalar(@EV::Pg::NEW), 0, '... and nothing was handed to EV::Pg';
}

# ---------------------------------------------------------------------------
# 5. The schema path: a Vault broker selects the mode in its DBI attributes.
# ---------------------------------------------------------------------------

{
  package BrokerSchema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('PostgreSQL');
}

{
  my $schema = BrokerSchema->connect(vault());
  my $async  = eval { $schema->storage->async };
  isa_ok $async, 'DBIO::PostgreSQL::EV::Storage',
    'MyApp::Schema->connect($vault) with dbi_attrs { async => ev }'
    or diag $@;
  is_deeply eval { parse_conninfo(spawn_conninfo($async)) },
    { dbname => 'appdb', host => 'db.example', port => 5433,
      user => 'vault-user-1', password => 'vault-pw-1' },
    '... connects its pool from the broker: DSN parts, user and password, no async attribute'
    or diag $@;
}

# ---------------------------------------------------------------------------
# 6. One reading path: core's seam is asked for every connection.
# ---------------------------------------------------------------------------

# Core names _current_async_connect_info as where an async storage reads its
# broker: connect_info asks it, "and so does a transport building each pool
# connection's conninfo" (DBIO::Storage::Async). The attach read it there
# (karr k60) while the pool spawn and the listen open asked the broker by
# another method -- two reading paths, so whatever is decided at the seam held
# for the attach and for no connection after it. With core as it stands the two
# paths answer alike; the difference shows where the seam is overridden, so
# this storage overrides it: it counts the calls and marks the answer.
{
  package SeamStorage;
  use base 'DBIO::PostgreSQL::EV::Storage';

  our $ASKED = 0;

  sub _current_async_connect_info {
    my $self = shift;
    my $info = $self->SUPER::_current_async_connect_info(@_);
    $ASKED++;
    return [ { %{ $info->[0] }, application_name => 'read-at-the-seam' }, $info->[1] ];
  }
}

{
  my %answer = ( dbname => 'appdb', user => 'app', password => 'pw' );
  my %want   = ( %answer, application_name => 'read-at-the-seam' );

  my $s = SeamStorage->new(undef);
  $s->connect_info([ AnswerBroker->new({ %answer }) ]);
  is $SeamStorage::ASKED, 1, 'attaching the broker reads its answer at the seam, once';

  my $pool = eval { parse_conninfo(spawn_conninfo($s)) };
  is $SeamStorage::ASKED, 2, 'a pool spawn reads it at the seam too, once';
  is_deeply $pool, \%want, '... and connects from what the seam returned' or diag $@;

  my $listen = eval { parse_conninfo(listen_conninfo($s)) };
  is $SeamStorage::ASKED, 3, 'a listen open reads it at the seam too, once';
  is_deeply $listen, \%want, '... and connects from what the seam returned' or diag $@;
}

# ---------------------------------------------------------------------------
# 7. A broker detached behind the transport's back.
# ---------------------------------------------------------------------------

# clear_access_broker is public on DBIO::Storage, and called directly it leaves
# the per-spawn provider in place. The seam of section 6 answers what
# connect_info stored when no broker is attached. Before karr k63 that was the
# answer the broker gave at attach, and opening a connection from it is what
# core k249 abolished: the credentials of an earlier answer, which the broker
# may have rotated out. Since k63 nothing is stored from an answer (section 8),
# so the seam answers no conninfo -- and the provider must not read that as a
# broker's answer either: the refusal says what is wrong, that no broker is
# attached, instead of naming the shape of an answer no broker gave.
{
  my $s = transport_with(AnswerBroker->new({ dbname => 'appdb', user => 'app', password => 'hunter2' }));
  $s->clear_access_broker;
  @EV::Pg::NEW = ();

  my $f = $s->pool->acquire;
  ok $f->is_failed, 'broker detached: a pool spawn fails';
  my ($spawn_err) = $f->is_failed ? $f->failure : ('');
  like $spawn_err, qr/no AccessBroker attached/, '... saying that no broker is attached';
  unlike $spawn_err, qr/AccessBroker returned/, '... not that a broker answered something unusable';
  unlike $spawn_err, qr/hunter2/, '... without the password of the earlier answer';

  my $ok  = eval { $s->_listen_open; 1 };
  my $err = $@;
  ok !$ok, 'broker detached: a listen open croaks';
  like $err, qr/no AccessBroker attached/, '... saying that no broker is attached';
  unlike $err, qr/AccessBroker returned/, '... not that a broker answered something unusable';
  unlike $err, qr/hunter2/, '... without the password of the earlier answer';

  is scalar(@EV::Pg::NEW), 0,
    '... and nothing was handed to EV::Pg: no connection from the answer of the attach';
}

# ---------------------------------------------------------------------------
# 8. No conninfo is kept from a broker's answer.
# ---------------------------------------------------------------------------

# Every place in the storage where a plain value contains $needle, as a path.
# A broker is not looked into: it is the one that may hold the password. Code
# is not looked into either.
sub holding {
  my ($value, $needle, $path, $seen) = @_;
  $path //= '$storage';
  $seen //= {};
  return () unless defined $value;
  return index($value, $needle) >= 0 ? ($path) : () unless ref $value;
  return () if Scalar::Util::blessed($value) && $value->isa('DBIO::AccessBroker');
  return () if $seen->{ Scalar::Util::refaddr($value) }++;
  my $type = Scalar::Util::reftype($value);
  return map { holding($value->{$_}, $needle, "$path\->{$_}", $seen) } sort keys %$value
    if $type eq 'HASH';
  return map { holding($value->[$_], $needle, "$path\->[$_]", $seen) } 0 .. $#$value
    if $type eq 'ARRAY';
  return holding($$value, $needle, "\${ $path }", $seen)
    if $type eq 'SCALAR' || $type eq 'REF';
  return ();
}

# What a storage does when asked for a connection: how a pool spawn and a
# listen open end (the error without its location), and what reached EV::Pg.
sub connection_attempts {
  my ($s) = @_;
  @EV::Pg::NEW = ();
  my %got;
  for my $attempt (
    [ pool   => sub { my $f = $s->pool->acquire; die +($f->failure)[0] if $f->is_failed } ],
    [ listen => sub { $s->_listen_open } ],
  ) {
    my ($name, $code) = @$attempt;
    $got{$name} = eval { $code->(); 1 } ? 'no error' : $@ =~ s/ at \S+ line \d+\.?\n?\z//r;
  }
  $got{handles} = [ map { $_->[0] } @EV::Pg::NEW ];
  return \%got;
}

# A storage that was never given connect info: what "nothing to connect from"
# looks like on this transport.
my $unconfigured = connection_attempts(DBIO::PostgreSQL::EV::Storage->new(undef));
isnt $unconfigured->{pool},   'no error', 'a storage never given connect info: no pool connection';
isnt $unconfigured->{listen}, 'no error', '... and no listen connection';
is_deeply $unconfigured->{handles}, [], '... nothing reaches EV::Pg';

for my $broker_case (
  [ 'Static (a hash of parameters)',
    sub { static(password => 'static-pw') }, 'static-pw' ],
  [ 'Vault (the DBI form)',
    sub { vault() }, 'vault-pw-1' ],
  [ 'a libpq conninfo string',
    sub { AnswerBroker->new([ 'host=db.example dbname=appdb user=app password=string-pw' ]) }, 'string-pw' ],
) {
  my ($broker_label, $build, $password) = @$broker_case;

  for my $form_case (
    [ '[ $broker ]',            sub { [ $_[0] ] } ],
    [ '[ $broker, \%options ]', sub { [ $_[0], { pool_size => 3, pg_enable_utf8 => 1 } ] } ],
  ) {
    my ($form_label, $form) = @$form_case;
    my $label = "$broker_label as $form_label";

    my $attach = sub {
      my $s = DBIO::PostgreSQL::EV::Storage->new(undef);
      $s->connect_info($form->($build->()));
      return $s;
    };

    # Attached.
    my $s = $attach->();
    ok $s->access_broker && $s->_conninfo_provider, "$label: the broker is attached, with its provider";
    is $s->{_conninfo}, undef, '... and no conninfo is kept from its answer';
    is_deeply [ holding($s, $password) ], [],
      '... the password of the answer is nowhere in the storage object but in the broker';
    is eval { parse_conninfo(spawn_conninfo($s))->{password} }, $password,
      '... while a connection still gets it, from the broker'
      or diag $@;

    # The broker taken away, its provider left in place (section 7): core's
    # seam is all that could still name the earlier answer.
    my $taken = $attach->();
    $taken->clear_access_broker;
    my $info = $taken->_current_async_connect_info('write');
    ok !defined $info->[0],
      "$label, broker taken away: core's seam does not answer the broker's earlier answer";

    # Broker and provider gone, as core's _clear_access_broker leaves a
    # storage: nothing stands between a connection and what is stored.
    my $gone = $attach->();
    $gone->_clear_access_broker;
    is $gone->_conninfo_string, undef,
      "$label, broker and provider gone: there is no conninfo to render";
    my $attempts = connection_attempts($gone);
    is_deeply $attempts->{handles}, [],
      '... no connection is opened from the earlier answer';
    unlike "$attempts->{pool} $attempts->{listen}", qr/\Q$password\E/,
      '... and no error carries its password';
    is_deeply $attempts, $unconfigured,
      '... the storage has nothing to connect from, like one never given connect info';
  }
}

# Static connect info is what a static connection is opened from, so it stays
# stored -- and each change between a broker and static connect info leaves
# only what belongs to the new one.
{
  my $s = DBIO::PostgreSQL::EV::Storage->new(undef);

  $s->connect_info([ static(password => 'first-broker-pw') ]);
  is $s->{_conninfo}, undef, 'a broker first: no conninfo is stored';
  is eval { parse_conninfo(spawn_conninfo($s))->{password} }, 'first-broker-pw',
    '... a pool connection is opened from the broker'
    or diag $@;

  my %static = ( dbname => 'staticdb', host => 'static.example', user => 'static-user', password => 'static-pw' );
  $s->connect_info([ 'dbi:Pg:dbname=staticdb;host=static.example', 'static-user', 'static-pw' ]);
  ok !$s->access_broker && !$s->_conninfo_provider,
    'then static connect info: the broker and its provider are gone';
  is_deeply $s->{_conninfo}, \%static, '... and the static conninfo is stored';
  is_deeply [ holding($s, 'first-broker-pw') ], [], "... with nothing left of the broker's answer";
  is_deeply eval { parse_conninfo($s->_conninfo_string) }, \%static,
    '... _conninfo_string renders it'
    or diag $@;
  is_deeply eval { parse_conninfo(spawn_conninfo($s)) }, \%static,
    '... a pool connection is opened from it'
    or diag $@;
  is_deeply eval { parse_conninfo(listen_conninfo($s)) }, \%static,
    '... and so is the listen connection'
    or diag $@;

  $s->connect_info([ static(password => 'second-broker-pw'), { pool_size => 2 } ]);
  ok $s->access_broker && $s->_conninfo_provider, 'then a broker again: it is attached, with its provider';
  is $s->{_conninfo}, undef, '... and no conninfo is stored: neither its answer nor the static one before it';
  is_deeply [ holding($s, 'static-pw') ], [], '... the static password is gone from the storage object';
  is_deeply [ holding($s, 'second-broker-pw') ], [], "... and the broker's is nowhere but in the broker";
  is eval { parse_conninfo(spawn_conninfo($s))->{password} }, 'second-broker-pw',
    '... a pool connection is opened from the second broker'
    or diag $@;

  $s->_clear_access_broker;
  is_deeply connection_attempts($s)->{handles}, [],
    '... and with that broker gone, none is opened from the static connect info before it';
}

# ---------------------------------------------------------------------------
# 9. A broker that cannot be attached leaves no static conninfo behind.
# ---------------------------------------------------------------------------

# A broker that cannot be reached: asking it throws.
{
  package ThrowingBroker;
  use base 'DBIO::AccessBroker';
  sub new { bless {}, shift }
  sub connect_info_for { die "k67 vault unreachable\n" }
}

# Every value of the static connect info of this section carries $K67_STATIC,
# so one needle finds any of it -- in the storage object, in an error, in what
# reaches EV::Pg.
my $K67_STATIC = 'k67-static';
my @k67_static_info = ( 'dbi:Pg:dbname=k67-static-db;host=k67-static.example', 'k67-static-user', 'k67-static-pw' );
my %k67_static = (
  dbname => 'k67-static-db', host => 'k67-static.example',
  user   => 'k67-static-user', password => 'k67-static-pw',
);

# Control: static connect info is stored and found by the scanner, so "nothing
# of it is left" below is said of something that was there.
{
  my $s = DBIO::PostgreSQL::EV::Storage->new(undef);
  $s->connect_info([ @k67_static_info ]);
  is_deeply $s->{_conninfo}, \%k67_static, 'static connect info: its conninfo is stored';
  ok scalar(holding($s, $K67_STATIC)), '... and the scanner finds it in the storage object';
}

# [ label, connect info, the error, what a connection is opened from while the
#   broker stays attached -- nothing, where its answer is the trouble ]
for my $case (
  [ 'the broker throws',
    sub { [ ThrowingBroker->new ] },
    qr/^k67 vault unreachable/ ],
  [ 'the broker answers nothing',
    sub { [ AnswerBroker->new(undef) ] },
    $NOTHING ],
  [ 'the broker answers a shape the transport cannot read',
    sub { [ AnswerBroker->new('host=db.example password=hunter2') ] },
    $CANNOT ],
  [ 'the broker answers what renders to the empty conninfo',
    sub { [ AnswerBroker->new({ pool_size => 3 }) ] },
    $CANNOT ],
  [ 'the pool size in the answer and the one beside the broker disagree',
    sub { [ AnswerBroker->new({ dbname => 'appdb', user => 'app', password => 'broker-pw', pool_size => 2 }),
            { pool_size => 3 } ] },
    qr/Connection setting 'pool_size' is given both beside the AccessBroker and in the broker's answer/,
    { dbname => 'appdb', user => 'app', password => 'broker-pw' } ],
) {
  my ($label, $broker_info, $error, $from_broker) = @$case;

  for my $pooled (0, 1) {
    my $t = $label . ($pooled ? ', the static connection pooled' : '');

    for my $detach (qw( _clear_access_broker clear_access_broker )) {
      my $s = DBIO::PostgreSQL::EV::Storage->new(undef);
      $s->connect_info([ @k67_static_info ]);
      if ($pooled) {
        is_deeply eval { parse_conninfo(spawn_conninfo($s)) }, \%k67_static,
          "$t: the static connection has a pool connection"
          or diag $@;
      }

      my $info = $broker_info->();
      my $ok   = eval { $s->connect_info($info); 1 };
      my $err  = $@;
      ok !$ok, "$t: connect_info throws";
      like $err, $error, '... the error of the attach';
      unlike $err, qr/\Q$K67_STATIC\E/, '... naming no value of the static connect info';

      # The static conninfo is gone.
      is $s->{_conninfo}, undef, "$t: the static conninfo is not kept";
      is_deeply [ holding($s, $K67_STATIC) ], [],
        '... nor anything of it, anywhere in the storage object';

      # While the broker stays attached, a connection asks it.
      is $s->access_broker, $info->[0], "$t: the broker is attached";
      {
        my $attached = connection_attempts($s);
        if ($from_broker) {
          is_deeply [ map { eval { parse_conninfo($_) } } @{ $attached->{handles} } ],
            [ $from_broker, $from_broker ],
            '... with it attached, a pool and the listen connection are opened from its answer';
        }
        else {
          isnt $attached->{pool},   'no error', '... with it attached, a pool connection fails';
          isnt $attached->{listen}, 'no error', '... and so does a listen open';
          is_deeply $attached->{handles}, [], '... nothing reaches EV::Pg';
        }
        unlike join(' ', $attached->{pool}, $attached->{listen}, @{ $attached->{handles} }),
          qr/\Q$K67_STATIC\E/,
          '... and nothing of the static connect info is in what happened';
        $s->disconnect;   # the pool built for that attempt goes with it
      }

      # The broker detached: nothing to fall back to.
      $s->$detach;
      ok !$s->access_broker, "$t, $detach: the broker is detached";
      ok !defined $s->_current_async_connect_info('write')->[0],
        "... core's seam answers no conninfo: not the static one of before";
      my $detached = connection_attempts($s);
      is_deeply $detached->{handles}, [],
        '... no connection is opened from the static connect info';
      unlike "$detached->{pool} $detached->{listen}", qr/\Q$K67_STATIC\E/,
        '... and no error carries a value of it';
      if ($detach eq '_clear_access_broker') {
        is_deeply $detached, $unconfigured,
          '... the storage has nothing to connect from, like one never given connect info';
      }
      else {
        # Behind the transport's back the provider stays in place (section 7).
        like $detached->{pool}, qr/no AccessBroker attached/,
          '... a pool spawn says that no broker is attached';
        like $detached->{listen}, qr/no AccessBroker attached/,
          '... and so does a listen open';
      }
    }
  }
}

# A storage whose attach failed takes static connect info again.
{
  my $s = DBIO::PostgreSQL::EV::Storage->new(undef);
  $s->connect_info([ @k67_static_info ]);
  ok !eval { $s->connect_info([ ThrowingBroker->new ]); 1 },
    'static connect info, then a broker that throws';
  ok eval { $s->connect_info([ @k67_static_info ]); 1 }, '... then static connect info again: it is taken'
    or diag $@;
  ok !$s->access_broker && !$s->_conninfo_provider, '... the broker and its provider are gone';
  is_deeply eval { parse_conninfo(spawn_conninfo($s)) }, \%k67_static,
    '... and a pool connection is opened from it'
    or diag $@;
}

done_testing;
