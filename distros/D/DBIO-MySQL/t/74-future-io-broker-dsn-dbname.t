use strict;
use warnings;
use Test::More;

# OFFLINE test (karr k67; dbio-async k44, sister of dbio-postgresql k97): an
# AccessBroker whose dbname is a whole DSN, on the future_io transport --
# DBD::mysql and DBD::MariaDB flavour, pool connection and listen connection.
#
# WHY. DBIO::AccessBroker::Static names no driver; its documented way to a
# DSN its three parts cannot spell is the whole DSN as dbname. Core reads it
# so (ADR 0057): a dbname that starts with 'dbi:' IS the DSN. In this dist it
# is more than a convenience -- it is the one way a Static broker reaches the
# OTHER DBD under either schema component (t/72 pins that for the sync
# storage). dbio-async reads a broker's parameter hash for the future_io
# backend, and until its k44 it took the DSN and left host and port beside it
# among the DBD attributes. For these two DBDs an attribute of that name is not
# inert, and they disagree about it (t/72: DBD::MariaDB lays the attributes
# over the parsed DSN, DBD::mysql the other way round) -- so a host beside a
# DSN dbname sent the backend to another server than the owning sync storage,
# on one DBD and not the other, and even without one a Static broker handed
# DBI->connect a host and a port of undef. This transport inherits
# dbio-async's _async_broker_conninfo and with it the fix (t/73 pins the
# inheritance); this file holds both connections it opens to it. The listen
# connection is opened by this dist's own seam and by nothing dbio-async tests.
#
# What this file claims:
#   1. a dbname that starts with 'dbi:' reaches DBI->connect as the DSN,
#      unchanged -- from Static, from a parameter hash, with connect options
#      beside the broker, with an owning sync storage and without one, for a
#      pool connection and for the listen connection alike. The DSN decides
#      the DBD: under either class a dbi:mysql: and a dbi:MariaDB: DSN each
#      get the auto-reconnect switch of their own DBD (karr k60). user,
#      password and every other key keep their meaning; host, port and dbname
#      are never among the attributes, set or empty;
#   2. through a schema, the backend opens the DSN the owning sync storage
#      opens -- the two cannot name different servers;
#   3. a host or port set beside such a dbname is refused, in the words the
#      sync storage uses, and nothing is sent to DBI->connect: not for a pool
#      connection, not for the listen connection, not through listen(), whose
#      Future fails and whose on_listen_error is told. The error names the
#      keys, never a value;
#   4. the refusal belongs to the DSN dbname only: host and port beside a
#      database name still go into the DSN the owner builds.
#
# WHAT RUNS FOR REAL: the schema components, the built-in brokers, core's
# broker attach, per-spawn provider and listen machinery, the real pool,
# dbio-async's _async_broker_conninfo and this dist's shipped seams.
# THE SUBSTITUTION: DBI->connect records its arguments and hands out a fake
# handle of the DBD the DSN names -- the MariaDB one refusing a mysql_*
# attribute, as DBD::MariaDB 1.24 does (measured for karr k59 / k60).
# NOT PROVEN HERE: what the real DBDs do with such a DSN (live only).

BEGIN {
  eval { require DBIO::MySQL::Storage::Async; require DBIO::MySQL::Storage::MariaDB::Async; 1 }
    or plan skip_all =>
      'DBIO::Async not installed (recommends only) -- future_io transport unavailable';
  plan skip_all => 'the installed dbio-async predates _async_broker_conninfo'
    unless DBIO::Async::Storage->can('_async_broker_conninfo');
  plan skip_all => 'the installed DBIO core predates the LISTEN/NOTIFY contract (core k219)'
    unless DBIO::Storage::Async->can('listen_alive');
}

use DBIO::MySQL::Storage ();
use DBIO::MySQL::Storage::MariaDB ();
use DBIO::AccessBroker::Static;
use DBIO::AccessBroker::HostBound;

our (@CONNECTS, @OWNERS, @WARNINGS);

$SIG{__WARN__} = sub { push @WARNINGS, @_ };

{
  package K67Dsn::DBH;
  sub new { my ($class, $dbd) = @_; bless { Active => 1, Driver => { Name => $dbd } }, $class }
  sub disconnect { $_[0]{Active} = 0; 1 }
  sub do { 1 }   # the session statement of every connection (karr k121)
}

{
  no warnings 'redefine';
  *DBI::connect = sub {
    my ($class, $dsn, $user, $password, $attrs) = @_;
    my ($dbd) = ($dsn // '') =~ /^dbi:(\w*)/i;
    if ($dbd eq 'MariaDB') {
      die "DBI connect failed: Unknown attribute $_\n"
        for sort grep { /^mysql_/ } keys %$attrs;
    }
    push @CONNECTS, [ $dsn, $user, $password, { %$attrs } ];
    return K67Dsn::DBH->new($dbd);
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
  package K67Dsn::MySQLSchema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('MySQL');

  package K67Dsn::MariaDBSchema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('MySQL::MariaDB');
}

# Each DBD's own names, spelled out on purpose: the expectation must not be
# derived from the table under test.
my %DBD = (
  mysql   => { reconnect => 'mysql_auto_reconnect',   timeout => 'mysql_connect_timeout' },
  MariaDB => { reconnect => 'mariadb_auto_reconnect', timeout => 'mariadb_connect_timeout' },
);

my %FLAVOUR = (
  mysql => {
    schema => 'K67Dsn::MySQLSchema',
    sync   => 'DBIO::MySQL::Storage',
    async  => 'DBIO::MySQL::Storage::Async',
  },
  MariaDB => {
    schema => 'K67Dsn::MariaDBSchema',
    sync   => 'DBIO::MySQL::Storage::MariaDB',
    async  => 'DBIO::MySQL::Storage::MariaDB::Async',
  },
);

my %FORCED = (AutoCommit => 1, RaiseError => 1, PrintError => 0, AutoInactiveDestroy => 1);

# The backend as the schema path builds it -- with its owning sync storage --
# or, with owner => 0, constructed by itself.
sub transport_with {
  my ($flavour, $info, %opt) = @_;
  my $f = $FLAVOUR{$flavour};
  my $s = $f->{async}->new(undef);
  if ($opt{owner} // 1) {
    my $owner = bless {}, $f->{sync};
    push @OWNERS, $owner;   # the backend holds its owner weakly
    $s->_owner_storage($owner);
  }
  $s->connect_info(ref $info eq 'ARRAY' ? $info : [ $info ]);
  return $s;
}

# One new pool connection: acquired and kept, so the next spawn is a new one.
sub spawn       { my ($s) = @_; @CONNECTS = (); $s->pool->acquire->get; return $CONNECTS[-1] }
sub open_listen { my ($s) = @_; @CONNECTS = (); $s->_listen_open->get; return $CONNECTS[-1] }

my @OPENS = (
  [ 'a pool connection',     \&spawn ],
  [ 'the listen connection', \&open_listen ],
);

my @PARTS = qw( dbname host port );

# The words the sync storage has for a host beside a DSN dbname, read off the
# installed core rather than copied here: the backend has to say the same.
my $core_refusal = do {
  my $storage = DBIO::MySQL::Storage->new(undef);
  eval { $storage->_dsn_from_connect_params({ dbname => 'dbi:mysql:database=appdb', host => 'h' }); 1 }
    and die 'core accepted a host beside a DSN dbname';
  my ($words) = $@ =~ /(Connection parameter\(s\) 'host' given beside .*? database name\.)/s
    or die "core's refusal reads differently now: $@";
  $words;
};

# The refusal naming these keys: core's sentence with its key list exchanged.
sub refusal_naming {
  my (@keys) = @_;
  (my $words = $core_refusal) =~ s/'host'/join ', ', map { "'$_'" } @keys/e;
  return $words;
}

for my $flavour (qw( mysql MariaDB )) {
  my $f = $FLAVOUR{$flavour};

  # A DSN of the class's own DBD, and one of the other: the DSN decides.
  for my $dbd ($flavour, grep { $_ ne $flavour } qw( mysql MariaDB )) {
    my $d   = $DBD{$dbd};
    my $DSN = "dbi:$dbd:database=appdb;host=db.example;port=3307";
    my $on  = "$flavour class, a dbi:$dbd: DSN";
    my %attrs = (%FORCED, $d->{reconnect} => 0);

    # -----------------------------------------------------------------------
    # 1. The dbname that is a DSN is the DSN.
    # -----------------------------------------------------------------------

    for my $case (
      [ 'Static',
        sub { DBIO::AccessBroker::Static->new(dbname => $DSN, username => 'app', password => 's3cret') },
        [ $DSN, 'app', 's3cret', { %attrs } ] ],
      [ 'Static, the backend without an owning sync storage',
        sub { DBIO::AccessBroker::Static->new(dbname => $DSN, username => 'app', password => 's3cret') },
        [ $DSN, 'app', 's3cret', { %attrs } ], owner => 0 ],
      [ 'a parameter hash, host and port empty beside it, and a DBD attribute',
        sub { HashBroker->new({
          dbname => "dbi:$dbd:database=appdb", host => '', port => undef,
          user => 'app', password => 's3cret', $d->{timeout} => 7,
        }) },
        [ "dbi:$dbd:database=appdb", 'app', 's3cret', { $d->{timeout} => 7, %attrs } ] ],
      [ 'a DSN spelled DBI:',
        sub { HashBroker->new({ dbname => "DBI:$dbd:database=appdb", user => 'app', password => 's3cret' }) },
        [ "DBI:$dbd:database=appdb", 'app', 's3cret', { %attrs } ] ],
      [ 'Static with a DBD attribute beside the broker',
        sub { [ DBIO::AccessBroker::Static->new(dbname => $DSN, username => 'app', password => 's3cret'),
                { $d->{timeout} => 7 } ] },
        [ $DSN, 'app', 's3cret', { $d->{timeout} => 7, %attrs } ] ],
    ) {
      my ($label, $build, $want, %opt) = @$case;
      my $s = transport_with($flavour, $build->(), %opt);

      for my $open (@OPENS) {
        my ($what, $code) = @$open;
        my $got = eval { $code->($s) };
        is_deeply $got, $want,
          "$on, $label: $what is opened with the dbname as its DSN, unchanged"
          or diag $@;
        is_deeply [ grep { exists $got->[3]{$_} } @PARTS ], [],
          '... and no part of the connection is among its DBD attributes'
          if $got;
      }
    }

    {
      my $s = transport_with($flavour, HashBroker->new({
        dbname => $DSN, user => 'app', password => 's3cret', pool_size => 2,
      }));
      is $s->pool->max_size, 2, "$on: pool_size beside a DSN dbname still sizes the pool";
      is_deeply scalar eval { spawn($s) }, [ $DSN, 'app', 's3cret', { %attrs } ],
        '... and is neither refused as a parameter beside it nor sent to DBI->connect'
        or diag $@;
    }

    # -----------------------------------------------------------------------
    # 2. Through a schema: the backend opens what the owning sync storage
    #    opens.
    # -----------------------------------------------------------------------

    {
      my $schema = $f->{schema}->connect(
        DBIO::AccessBroker::Static->new(dbname => $DSN, username => 'app', password => 's3cret'),
        { async => 'future_io' },
      );
      my $async = $schema->storage->async;
      isa_ok $async, $f->{async},
        "$on, a schema connected with a Static broker whose dbname is that DSN: the backend";

      my $sync_dsn = $schema->storage->_dbi_connect_info->[0];
      is $sync_dsn, $DSN, '... the owning sync storage reads the dbname as its DSN (core ADR 0057)';
      for my $open (@OPENS) {
        my ($what, $code) = @$open;
        is_deeply scalar eval { $code->($async) }, [ $sync_dsn, 'app', 's3cret', { %attrs } ],
          "... and $what of the backend is opened with that very DSN, and no part beside it"
          or diag $@;
      }
    }

    # -----------------------------------------------------------------------
    # 3. A host or port set beside a DSN dbname.
    # -----------------------------------------------------------------------

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
      [ 'host, the backend without an owning sync storage',
        sub { HashBroker->new({ dbname => $DSN, host => 'other-host.example', user => 'app', password => 'hunter2' }) },
        [ 'host' ], owner => 0 ],
    ) {
      my ($label, $build, $keys, %opt) = @$case;
      my $s = transport_with($flavour, $build->(), %opt);
      my $want   = refusal_naming(@$keys);
      my $values = qr/hunter2|other-host|6432|appdb|db\.example|3307/;

      for my $open (@OPENS) {
        my ($what, $code) = @$open;
        my $ok  = eval { $code->($s); 1 };
        my $err = $@;
        ok !$ok, "$on, $label set beside a DSN dbname: $what is refused";
        like $err, qr/\Q$want\E/,
          '... in the words of the sync storage, naming ' . join(', ', @$keys);
        unlike $err, $values,
          '... and no value: not the password, not the parameters, not the DSN';
        is scalar(@CONNECTS), 0, '... and nothing was sent to DBI->connect';
      }

      # The way an application meets it: listen(). Its open is the same seam,
      # and the refusal comes back through core -- the Future, and the hook.
      my @reports;
      $s->on_listen_error(sub { push @reports, $_[1] });
      $s->listen_backoff_initial(60);
      $s->listen_backoff_max(60);
      @CONNECTS = ();
      my $f_listen = $s->listen(jobs => sub { });
      ok $f_listen->is_ready && $f_listen->is_failed,
        "$on, $label set beside a DSN dbname: listen() fails its Future";
      like +($f_listen->failure)[0], qr/\Aopening the listen connection failed: .*\Q$want\E/s,
        '... saying why';
      like $reports[0] // '', qr/\Q$want\E/, '... and on_listen_error is told';
      unlike join(' ', ($f_listen->failure)[0], @reports), $values, '... neither naming a value';
      is scalar(@CONNECTS), 0, '... and nothing was sent to DBI->connect';
      $s->disconnect;
    }
  }

  # -------------------------------------------------------------------------
  # 4. The same parameters beside a database name still go into the DSN.
  # -------------------------------------------------------------------------

  {
    my $s = transport_with($flavour, HashBroker->new({
      dbname => 'appdb', host => 'db.example', port => 3307, user => 'app', password => 's3cret',
    }));
    my %attrs = (%FORCED, $DBD{$flavour}{reconnect} => 0);
    for my $open (@OPENS) {
      my ($what, $code) = @$open;
      is_deeply scalar eval { $code->($s) },
        [ "dbi:$flavour:dbname=appdb;host=db.example;port=3307", 'app', 's3cret', { %attrs } ],
        "$flavour class, host and port beside a database name: $what gets them in the DSN the owner builds"
        or diag $@;
    }

    $s = transport_with($flavour, HashBroker->new({ dbname => 'dbimport', user => 'app', password => 's3cret' }));
    is scalar eval { open_listen($s)->[0] }, "dbi:$flavour:dbname=dbimport",
      "$flavour class: a database name that merely starts with the letters dbi is a database name"
      or diag $@;
  }
}

is_deeply \@WARNINGS, [], 'nothing warned along the way';

done_testing;
