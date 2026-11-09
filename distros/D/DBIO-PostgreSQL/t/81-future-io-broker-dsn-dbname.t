use strict;
use warnings;
use Test::More;

# OFFLINE test: an AccessBroker whose dbname is a whole DSN, on the future_io
# transport (karr k97).
#
# WHY: DBIO::AccessBroker::Static documents the whole DSN as dbname
# (dbname => 'dbi:Pg:service=app') as the way to give a DSN its three parts
# cannot spell, and core reads it so (ADR 0057): a dbname that starts with
# 'dbi:' IS the DSN. This transport reads a broker's parameter hash itself
# and made a DSN part of every key, so that dbname became
# dbi:Pg:dbname='dbi:Pg:service=app' -- a database of that name. The owning
# sync storage connected to the database the DSN names while its future_io
# backend asked for one that does not exist. dbio-async took core's reading in
# its k44; that fix does not reach an adapter that overrides the seam.
#
# What this file claims:
#   1. a dbname that starts with 'dbi:' reaches DBI->connect as the DSN,
#      unchanged -- from Static, from a parameter hash, from a pair, with
#      connect options beside the broker, for a pool connection and for the
#      listen connection alike; user, password, attrs and pool_size keep their
#      meaning; an empty host or port beside it (Static answers the parts not
#      given as undef) is as none given;
#   2. through a schema, the backend opens the DSN the owning sync storage
#      opens -- the two can no longer name different databases;
#   3. a parameter set beside such a dbname is refused, and nothing is sent to
#      DBI->connect: host and port in core's own words, and every other
#      parameter this transport would otherwise write into the DSN as well --
#      a whole DSN has no place for it, and dropped it would be an sslmode or
#      a HostBound view's host silently lost. The error names the keys, never
#      a value;
#   4. the refusal belongs to the DSN dbname only: the same parameters beside
#      a database name still go into the DSN.
#
# WHAT RUNS FOR REAL: the built-in brokers, core's broker attach and per-spawn
# provider, the real pool, and this dist's shipped seams.
# THE SUBSTITUTION: DBI->connect records its arguments and hands out a fake
# handle.

BEGIN {
  eval { require DBIO::PostgreSQL::Storage::Async; 1 }
    or plan skip_all =>
      'DBIO::Async not installed (recommends only) -- future_io transport unavailable';
}

use DBIO::PostgreSQL::Storage;
use DBIO::AccessBroker::Static;
use DBIO::AccessBroker::HostBound;

our @CONNECTS;

{
  package FakeDsn::DBH;
  sub new { bless { Active => 1, pg_socket => 42 }, shift }
  sub disconnect { $_[0]{Active} = 0; 1 }
}

{
  no warnings 'redefine';
  *DBI::connect = sub {
    my ($class, $dsn, $user, $password, $attrs) = @_;
    push @CONNECTS, [ $dsn, $user, $password, { %$attrs } ];
    return FakeDsn::DBH->new;
  };
}

# Answers whatever the test gives it.
{
  package HashBroker;
  use base 'DBIO::AccessBroker';
  sub new { my ($class, $answer) = @_; bless { answer => $answer }, $class }
  sub connect_info_for { $_[0]{answer} }
}

{
  package DsnSchema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('PostgreSQL');
}

my %FORCED = (
  AutoCommit => 1, RaiseError => 1, PrintError => 0, AutoInactiveDestroy => 1,
  # every error DBI reports for the handle is raised by the transport (karr k120)
  HandleError => \&DBIO::PostgreSQL::Storage::Async::_pg_dbi_error,
);

my $DSN = 'dbi:Pg:dbname=appdb;host=db.example;port=5433';

sub transport_with {
  my ($info) = @_;
  my $s = DBIO::PostgreSQL::Storage::Async->new(undef);
  $s->connect_info(ref $info eq 'ARRAY' ? $info : [ $info ]);
  return $s;
}

# One new pool connection: acquired and kept, so the next spawn is a new one.
sub spawn {
  my ($s) = @_;
  @CONNECTS = ();
  $s->pool->acquire->get;
  return $CONNECTS[-1];
}

sub open_listen {
  my ($s) = @_;
  @CONNECTS = ();
  $s->_listen_open->get;
  return $CONNECTS[-1];
}

my @OPENS = (
  [ 'a pool connection',     \&spawn ],
  [ 'the listen connection', \&open_listen ],
);

# ---------------------------------------------------------------------------
# 1. The dbname that is a DSN is the DSN.
# ---------------------------------------------------------------------------

for my $case (
  [ 'Static',
    sub { DBIO::AccessBroker::Static->new(dbname => $DSN, username => 'app', password => 's3cret') },
    [ $DSN, 'app', 's3cret', { %FORCED } ] ],
  [ 'a parameter hash, host and port empty beside it',
    sub { HashBroker->new({
      dbname => 'dbi:Pg:service=app', host => '', port => undef,
      user => 'app', password => 's3cret', attrs => { pg_enable_utf8 => 1 },
    }) },
    [ 'dbi:Pg:service=app', 'app', 's3cret', { pg_enable_utf8 => 1, %FORCED } ] ],
  [ 'a parameter hash, another parameter empty beside it',
    sub { HashBroker->new({
      dbname => $DSN, sslmode => '', connect_timeout => undef, user => 'app', password => 's3cret',
    }) },
    [ $DSN, 'app', 's3cret', { %FORCED } ] ],
  [ 'a parameter hash paired with options',
    sub { HashBroker->new([ { dbname => $DSN, user => 'app', password => 's3cret' }, {} ]) },
    [ $DSN, 'app', 's3cret', { %FORCED } ] ],
  [ 'a DSN spelled DBI:Pg:',
    sub { HashBroker->new({ dbname => 'DBI:Pg:dbname=appdb', user => 'app', password => 's3cret' }) },
    [ 'DBI:Pg:dbname=appdb', 'app', 's3cret', { %FORCED } ] ],
  [ 'a DSN that would need quoting as a database name',
    sub { HashBroker->new({
      dbname => q{dbi:Pg:dbname='my db';host=db.example}, user => 'app', password => 's3cret',
    }) },
    [ q{dbi:Pg:dbname='my db';host=db.example}, 'app', 's3cret', { %FORCED } ] ],
  [ 'Static with a DBD attribute beside the broker',
    sub { [ DBIO::AccessBroker::Static->new(dbname => $DSN, username => 'app', password => 's3cret'),
            { pg_server_prepare => 0 } ] },
    [ $DSN, 'app', 's3cret', { pg_server_prepare => 0, %FORCED } ] ],
) {
  my ($label, $build, $want) = @$case;
  my $s = transport_with($build->());

  for my $open (@OPENS) {
    my ($what, $code) = @$open;
    is_deeply scalar eval { $code->($s) }, $want,
      "$label: $what is opened with the dbname as its DSN, unchanged"
      or diag $@;
  }
}

{
  my $s = transport_with(HashBroker->new({
    dbname => $DSN, user => 'app', password => 's3cret', pool_size => 2,
  }));
  is $s->pool->max_size, 2, 'pool_size beside a DSN dbname still sizes the pool';
  is_deeply scalar eval { spawn($s) }, [ $DSN, 'app', 's3cret', { %FORCED } ],
    '... and is neither refused as a parameter beside it nor sent to DBI->connect'
    or diag $@;
}

# ---------------------------------------------------------------------------
# 2. Through a schema: the backend opens what the owning sync storage opens.
# ---------------------------------------------------------------------------

{
  my $schema = DsnSchema->connect(
    DBIO::AccessBroker::Static->new(dbname => $DSN, username => 'app', password => 's3cret'),
    { async => 'future_io' },
  );
  my $async = $schema->storage->async;
  isa_ok $async, 'DBIO::PostgreSQL::Storage::Async',
    'a schema connected with a Static broker whose dbname is a DSN: the backend';

  my $sync_dsn = $schema->storage->_dbi_connect_info->[0];
  is $sync_dsn, $DSN, '... the owning sync storage reads the dbname as its DSN (core ADR 0057)';
  for my $open (@OPENS) {
    my ($what, $code) = @$open;
    is scalar eval { $code->($async)->[0] }, $sync_dsn,
      "... and $what of the backend is opened with that very DSN"
      or diag $@;
  }
}

# ---------------------------------------------------------------------------
# 3. A parameter set beside a DSN dbname.
# ---------------------------------------------------------------------------

# Core's own words for host beside a DSN dbname, read off the installed core
# rather than copied here: this transport has to say the same.
my $core_refusal = do {
  my $storage = DBIO::PostgreSQL::Storage->new(undef);
  eval { $storage->_dsn_from_connect_params({ dbname => $DSN, host => 'h' }); 1 }
    and die 'core accepted a host beside a DSN dbname';
  my ($words) = $@ =~ /(Connection parameter\(s\) 'host' given beside .*? database name\.)/s
    or die "core's refusal reads differently now: $@";
  $words;
};

# The refusal naming these keys: core's sentence with its key list exchanged.
# For host alone it is core's, word for word.
sub refusal_naming {
  my (@keys) = @_;
  (my $words = $core_refusal) =~ s/'host'/join ', ', map { "'$_'" } @keys/e;
  return $words;
}

for my $case (
  [ 'host',
    sub { HashBroker->new({ dbname => $DSN, host => 'other-host.example', user => 'app', password => 'hunter2' }) },
    [ 'host' ] ],
  [ 'port',
    sub { HashBroker->new({ dbname => $DSN, port => 6432, user => 'app', password => 'hunter2' }) },
    [ 'port' ] ],
  [ 'host and port',
    sub { DBIO::AccessBroker::Static->new(
      dbname => $DSN, host => 'other-host.example', port => 6432, username => 'app', password => 'hunter2',
    ) },
    [ 'host', 'port' ] ],
  [ 'the host of a HostBound view',
    sub { DBIO::AccessBroker::Static->new(dbname => $DSN, username => 'app', password => 'hunter2')
            ->for_host('other-host.example') },
    [ 'host' ] ],
  [ 'another libpq parameter',
    sub { HashBroker->new({ dbname => $DSN, sslmode => 'verify-full', user => 'app', password => 'hunter2' }) },
    [ 'sslmode' ] ],
  [ 'host and other libpq parameters',
    sub { HashBroker->new({
      dbname => $DSN, sslmode => 'verify-full', host => 'other-host.example', connect_timeout => 6432,
      user => 'app', password => 'hunter2', attrs => { pg_enable_utf8 => 1 },
    }) },
    [ 'connect_timeout', 'host', 'sslmode' ] ],
  [ 'a parameter that is a reference',
    sub { HashBroker->new({ dbname => $DSN, host => [ 'other-host.example' ], user => 'app', password => 'hunter2' }) },
    [ 'host' ] ],
) {
  my ($label, $build, $keys) = @$case;
  my $s = transport_with($build->());
  my $want = refusal_naming(@$keys);

  for my $open (@OPENS) {
    my ($what, $code) = @$open;
    my $ok  = eval { $code->($s); 1 };
    my $err = $@;
    ok !$ok, "$label set beside a DSN dbname: $what is refused";
    like $err, qr/\Q$want\E/,
      '... in core\'s words, naming ' . join(', ', @$keys);
    unlike $err, qr/hunter2|other-host|verify-full|6432|appdb|db\.example/,
      '... and no value: not the password, not the parameters, not the DSN';
    is scalar(@CONNECTS), 0, '... and nothing was sent to DBI->connect';
  }
}

# ---------------------------------------------------------------------------
# 4. The same parameters beside a database name still go into the DSN.
# ---------------------------------------------------------------------------

{
  my $s = transport_with(HashBroker->new({
    dbname => 'appdb', host => 'db.example', sslmode => 'verify-full', user => 'app', password => 's3cret',
  }));
  is_deeply scalar eval { spawn($s) },
    [ 'dbi:Pg:dbname=appdb;host=db.example;sslmode=verify-full', 'app', 's3cret', { %FORCED } ],
    'beside a database name, host and sslmode are parts of the DSN this transport builds'
    or diag $@;

  $s = transport_with(HashBroker->new({ dbname => 'dbimport', user => 'app', password => 's3cret' }));
  is scalar eval { spawn($s)->[0] }, 'dbi:Pg:dbname=dbimport',
    'a database name that merely starts with the letters dbi is a database name'
    or diag $@;
}

done_testing;
