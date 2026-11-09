use strict;
use warnings;
use Test::More;

# OFFLINE test: connect options beside an AccessBroker, and the fifth element
# of DBI-form connect info, on the future_io transport -- DBD::mysql and
# DBD::MariaDB flavour (karr k64; sister of dbio-postgresql k91).
#
# WHY. Core k243 (ADR 0030 addendum II) lets connect() take every connect
# option beside a broker, [ $broker, \%options ]. What the owning sync storage
# applies itself (async, quote_names, on_connect_do, ...) needs nothing from a
# backend. The DBD attributes and pool_size are different: the owner's own
# connection gets them, and core hands them to the async backend ONLY if its
# transport declares 'broker_connect_options' -- a promise that the transport
# applies them to every connection it opens. Without the declaration core
# throws at the first async use, because otherwise the pooled connections
# would silently run without settings the owner's connection has (a charset, a
# timeout, an SSL switch: the kind of difference nobody finds until
# production). So the declaration may only be made once the promise holds:
# this transport reads a broker's answer through dbio-async's
# _async_broker_conninfo, which merges the settings beside the broker in
# (dbio-async k27), and its own _mysql_connect hands the result to
# DBI->connect for the pool AND the listen connection.
#
# The second defect is the same silent loss without a broker: the transport's
# _normalize_conninfo read only slot [3] of DBI-form connect info, so DBD
# attributes or pool_size in the fifth element ([4], DBI's \%extra_attributes)
# never reached a pooled connection, although the sync storage merges both
# slots, the fifth winning (DBIO::Storage::DBI::_normalize_connect_info).
#
# What this file claims:
#   1. the transport declares broker_connect_options, a schema connected with
#      a broker plus a DBD attribute and pool_size beside it gets its future_io
#      backend -- and the declaration is the reason: with it taken away, core
#      refuses the very same connect;
#   2. a DBD attribute beside the broker reaches DBI->connect of a pool
#      connection AND of the listen connection, for every answer shape the
#      merge covers; nothing DBIO-private (async, pool_size, on_connect_do,
#      quote_names) comes along. An answer in the transport's own shape cannot
#      take them and is refused, never connected without them;
#   3. the merge rule: a setting beside the broker and in its answer connects
#      when both are the same and is refused, naming the setting, when they
#      differ -- nothing is sent to DBI->connect;
#   4. pool_size beside the broker sizes the pool: that many connections and
#      no more;
#   5. the DBD's auto-reconnect given beside the broker is respected on the
#      pool like one from slot [3] (this dist's ADR 0005: an explicit value is
#      the caller's informed choice), named for the DBD of the DSN (karr k60),
#      and still forced off on the listen connection;
#   6. options the owner applies keep working beside a broker that also
#      carries backend settings: quote_names on the owner, on_connect_do
#      replayed on the pooled connection;
#   7. DBI form without a broker: attributes and pool_size in slot [4] reach
#      the pool and the listen connection, [4] wins over [3] exactly as on the
#      owning sync storage, no DBIO-private key reaches DBI->connect, and an
#      auto-reconnect set there is respected.
#
# WHAT RUNS FOR REAL: the schema components, the sync storage's connect_info,
# core's async resolution, option split, pool sizing and merge rule, the
# built-in brokers, the real pool, dbio-async's _async_broker_conninfo and
# this dist's shipped seams. THE SUBSTITUTIONS: DBI->connect records its
# arguments and hands out a fake handle of the DBD the DSN names -- the
# MariaDB one refusing a mysql_* attribute, as DBD::MariaDB 1.24 does (measured
# for karr k59 / k60); the Vault client is a stub.
# NOT PROVEN HERE: that the real DBDs accept and apply these attributes, and
# that a real server sees no more than pool_size sessions (live only).

BEGIN {
  eval { require DBIO::MySQL::Storage::Async; require DBIO::MySQL::Storage::MariaDB::Async; 1 }
    or plan skip_all =>
      'DBIO::Async not installed (recommends only) -- future_io transport unavailable';
  plan skip_all => 'the installed DBIO core predates connect options beside an AccessBroker (core k243)'
    unless DBIO::Storage::Async->can('_access_broker_call_attributes');
}

use DBI;
use DBIO::Util ();
use DBIO::MySQL::Storage ();
use DBIO::MySQL::Storage::MariaDB ();
use DBIO::AccessBroker::Static;
use DBIO::AccessBroker::Vault;
use DBIO::AccessBroker::HostBound;

our (@CONNECTS, @OWNERS);

{
  package K64::DBH;
  sub new { my ($class, $dbd) = @_; bless { Active => 1, Driver => { Name => $dbd }, did => [] }, $class }
  sub disconnect { $_[0]{Active} = 0; 1 }
  sub do { push @{ $_[0]{did} }, $_[1]; 1 }
}

{
  no warnings 'redefine';
  *DBI::connect = sub {
    my ($class, $dsn, $user, $password, $attrs) = @_;
    my ($dbd) = ($dsn // '') =~ /^dbi:(\w*)/i;
    if ($dbd eq 'MariaDB') {
      die DBIO::Util::mask_connect_secrets(
          "DBI connect('$dsn') failed: Unknown attribute $_\n", [ $dsn, $user, $password ])
        for sort grep { /^mysql_/ } keys %$attrs;
    }
    my $dbh = K64::DBH->new($dbd);
    push @CONNECTS, { args => [ $dsn, $user, $password, { %$attrs } ], dbh => $dbh };
    return $dbh;
  };
}

{
  package FakeVaultClient;
  sub new { bless {}, shift }
  sub read_secret { return { username => 'vault-user', password => 'vault-pw' } }
}

{
  package HashBroker;
  use base 'DBIO::AccessBroker';
  sub new { my ($class, $answer) = @_; bless { answer => $answer }, $class }
  sub connect_info_for { $_[0]{answer} }
}

{
  package K64::MySQLSchema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('MySQL');

  package K64::MariaDBSchema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('MySQL::MariaDB');
}

# Each DBD's own names, spelled out on purpose: the expectation must not be
# derived from the table under test.
my %FLAVOUR = (
  mysql => {
    schema    => 'K64::MySQLSchema',
    sync      => 'DBIO::MySQL::Storage',
    async     => 'DBIO::MySQL::Storage::Async',
    reconnect => 'mysql_auto_reconnect',
    timeout   => 'mysql_connect_timeout',
    multi     => 'mysql_multi_statements',
    other     => 'MariaDB',
  },
  MariaDB => {
    schema    => 'K64::MariaDBSchema',
    sync      => 'DBIO::MySQL::Storage::MariaDB',
    async     => 'DBIO::MySQL::Storage::MariaDB::Async',
    reconnect => 'mariadb_auto_reconnect',
    timeout   => 'mariadb_connect_timeout',
    multi     => 'mariadb_multi_statements',
    other     => 'mysql',
  },
);

# What every connection of this transport forces on top of the caller's
# attributes; the DBD's auto-reconnect is added per case.
my %FORCED = (AutoCommit => 1, RaiseError => 1, PrintError => 0, AutoInactiveDestroy => 1);

# The transport as the schema path builds it: the backend with its owning
# sync storage (a Static broker's DSN is built by the owner), then the info.
sub transport_with {
  my ($flavour, $info) = @_;
  my $f = $FLAVOUR{$flavour};
  my $owner = bless {}, $f->{sync};
  push @OWNERS, $owner;   # the backend holds its owner weakly
  my $s = $f->{async}->new(undef);
  $s->_owner_storage($owner);
  $s->connect_info($info);
  return $s;
}

# The DBI->connect of one new pool connection (kept, so the next is new) and
# of the listen connection.
sub spawn       { my ($s) = @_; @CONNECTS = (); $s->pool->acquire->get; return $CONNECTS[-1]{args} }
sub open_listen { my ($s) = @_; @CONNECTS = (); $s->_listen_open->get; return $CONNECTS[-1]{args} }

for my $flavour (qw( mysql MariaDB )) {
  my $f   = $FLAVOUR{$flavour};
  my $dbd = $flavour;
  my ($reconnect, $timeout, $multi) = @{$f}{qw( reconnect timeout multi )};
  my $dsn = "dbi:$dbd:dbname=appdb;host=db.example;port=3307";

  my $static = sub {
    DBIO::AccessBroker::Static->new(
      host => 'db.example', port => 3307, dbname => 'appdb',
      username => 'app', password => 's3cret', @_,
    );
  };
  my $vault = sub {
    my (%attrs) = @_;
    DBIO::AccessBroker::Vault->new(
      vault     => FakeVaultClient->new,
      dsn       => delete($attrs{-dsn}) // $dsn,
      cred_path => 'database/creds/app',
      dbi_attrs => { async => 'future_io', %attrs },
    );
  };

  # -------------------------------------------------------------------------
  # 1. The declaration, core taking it -- and the declaration as the reason.
  # -------------------------------------------------------------------------

  ok scalar(grep { $_ eq 'broker_connect_options' } $f->{async}->transport_capabilities),
    "$flavour: transport_capabilities declares broker_connect_options";

  {
    my $schema = $f->{schema}->connect($static->(), {
      async => 'future_io', $timeout => 7, pool_size => 2,
    });
    my $async = eval { $schema->storage->async };
    isa_ok $async, $f->{async},
      "$flavour: a schema connected with a broker plus a DBD attribute and pool_size beside it: the future_io backend"
      or diag $@;

    SKIP: {
      skip 'no backend', 3 unless $async;
      my $want = [ $dsn, 'app', 's3cret', { $timeout => 7, %FORCED, $reconnect => 0 } ];
      is_deeply eval { spawn($async) }, $want,
        '... whose pool connection gets the attribute beside the broker -- and no async, no pool_size'
        or diag $@;
      is_deeply eval { open_listen($async) }, $want,
        '... and so does its listen connection'
        or diag $@;
      is $async->pool->max_size, 2, '... and pool_size beside the broker sized its pool';
    }
  }

  # The counterfactual: the same connect on the same transport without the
  # declaration. If this did not throw, the declaration above would not be
  # what lets the connect through, and section 2 would prove nothing about it.
  {
    no warnings 'redefine';
    local *DBIO::MySQL::Storage::Async::transport_capabilities =
      sub { qw(on_connect_replay listen notify) };

    my $schema = $f->{schema}->connect($static->(), {
      async => 'future_io', $timeout => 7, pool_size => 2,
    });
    @CONNECTS = ();
    ok !eval { $schema->storage->async; 1 },
      "$flavour, declaration taken away: core refuses the transport at the first async use";
    like $@, qr/does not declare 'broker_connect_options'/, '... saying what is missing';
    like $@, qr/\Q$timeout\E.*pool_size|pool_size.*\Q$timeout\E/s, '... and which settings it is about';
    is scalar(@CONNECTS), 0, '... before anything connects';

    ok !eval { transport_with($flavour, [ $static->(), { $timeout => 7 } ]); 1 },
      '... and the transport itself refuses the options when handed them directly';
    like $@, qr/does not declare 'broker_connect_options'/, '... for the same reason';
  }

  # -------------------------------------------------------------------------
  # 2. Each answer shape: the attribute beside the broker, pool and listen.
  # -------------------------------------------------------------------------

  for my $case (
    [ 'Static (connection parameters)',
      sub { $static->() },
      [ $dsn, 'app', 's3cret' ], {} ],
    [ 'Vault (DBI form)',
      sub { $vault->($multi => 1) },
      [ $dsn, 'vault-user', 'vault-pw' ], { $multi => 1 } ],
    [ 'HostBound over Static',
      sub { $static->()->for_host({ host => 'replica.example', port => 3308 }) },
      [ "dbi:$dbd:dbname=appdb;host=replica.example;port=3308", 'app', 's3cret' ], {} ],
    [ 'DBI form with a fifth element',
      sub { HashBroker->new([ "dbi:$dbd:dbname=appdb", 'u', 'p', { $multi => 1 }, { ReadOnly => 0 } ]) },
      [ "dbi:$dbd:dbname=appdb", 'u', 'p' ], { $multi => 1, ReadOnly => 0 } ],
  ) {
    my ($label, $build, $want_args, $answer_attrs) = @$case;
    # What the owner hands its backend once the hash holds a backend setting:
    # the whole hash, owner-side options included.
    my $s = eval {
      transport_with($flavour, [ $build->(), {
        $timeout => 7, async => 'future_io', quote_names => 1,
        on_connect_do => [ 'SET @k64 = 1' ],
      } ]);
    };
    ok $s, "$flavour/$label: the broker with options beside it attaches" or diag $@;
    next unless $s;

    my $want = [ @$want_args, { %$answer_attrs, $timeout => 7, %FORCED, $reconnect => 0 } ];
    is_deeply eval { spawn($s) }, $want,
      "$flavour/$label: a pool connection gets the DBD attribute beside the broker, nothing DBIO-private"
      or diag $@;
    is_deeply eval { open_listen($s) }, $want,
      "$flavour/$label: the listen connection gets it too"
      or diag $@;
  }

  # The transport's own shape carries its attributes in the driver's layout,
  # so dbio-async cannot merge into it. The promise is "every connection gets
  # them": a refusal keeps it, a connection without them would break it.
  {
    my $own = sub {
      HashBroker->new({ dsn => "dbi:$dbd:dbname=appdb", user => 'u', password => 'hunter2',
                        attrs => { $multi => 1 } });
    };
    is_deeply eval { spawn(transport_with($flavour, [ $own->() ])) },
      [ "dbi:$dbd:dbname=appdb", 'u', 'hunter2', { $multi => 1, %FORCED, $reconnect => 0 } ],
      "$flavour/the transport's own shape, nothing beside the broker: connects from it"
      or diag $@;

    my $s = eval { transport_with($flavour, [ $own->(), { $timeout => 7 } ]) };
    for my $open (
      [ 'a pool spawn',    sub { spawn($s) } ],
      [ 'the listen open', sub { open_listen($s) } ],
    ) {
      my ($where, $code) = @$open;
      @CONNECTS = ();
      my $ok  = $s && eval { $code->(); 1 };
      my $err = $@;
      ok !$ok, "$flavour/the transport's own shape with a DBD attribute beside the broker: $where is refused";
      like $err, qr/\Q$timeout\E.*cannot be merged/s, '... naming the attribute that cannot be merged';
      unlike $err, qr/hunter2/, '... never the password';
      is scalar(@CONNECTS), 0, '... and nothing connects without it';
    }
  }

  # -------------------------------------------------------------------------
  # 3. The merge rule: a setting beside the broker and in its answer.
  # -------------------------------------------------------------------------

  {
    my $same = eval { transport_with($flavour, [ $vault->($timeout => 7), { $timeout => 7 } ]) };
    is eval { spawn($same)->[3]{$timeout} }, 7,
      "$flavour: the same value beside the broker and in its answer connects"
      or diag $@;

    my $differ = eval { transport_with($flavour, [ $vault->($timeout => 7), { $timeout => 30 } ]) };
    for my $open (
      [ 'a pool spawn',    sub { spawn($differ) } ],
      [ 'the listen open', sub { open_listen($differ) } ],
    ) {
      my ($where, $code) = @$open;
      @CONNECTS = ();
      my $ok  = $differ && eval { $code->(); 1 };
      my $err = $@;
      ok !$ok, "$flavour, different values: $where is refused";
      like $err, qr/Connection setting '\Q$timeout\E' is given both beside the AccessBroker and in the broker's answer/,
        '... naming the setting';
      is scalar(@CONNECTS), 0, '... and nothing was sent to DBI->connect';
    }

    # pool_size follows the same rule, when the broker is attached.
    is eval { transport_with($flavour, [ $vault->(pool_size => 3), { pool_size => 3 } ])->pool->max_size }, 3,
      "$flavour: the same pool_size beside the broker and in its answer sizes the pool"
      or diag $@;
    ok !eval { transport_with($flavour, [ $vault->(pool_size => 3), { pool_size => 4 } ]); 1 },
      "$flavour: a different pool_size is refused";
    like $@, qr/Connection setting 'pool_size' is given both/, '... naming it';
  }

  # -------------------------------------------------------------------------
  # 4. pool_size beside the broker sizes the pool.
  # -------------------------------------------------------------------------

  {
    my $s = transport_with($flavour, [ $static->(), { pool_size => 3 } ]);
    is $s->pool->max_size, 3, "$flavour: pool_size 3 beside the broker: the pool is sized 3";

    @CONNECTS = ();
    my @held = map { $s->pool->acquire } 1 .. 4;
    is scalar(@CONNECTS), 3, '... four acquires open exactly three connections';
    is scalar(grep { $_->is_ready } @held), 3, '... and the fourth waits for one of them';
    ok !grep({ exists $_->{args}[3]{pool_size} } @CONNECTS), '... pool_size is no DBD attribute';
    $s->pool->shutdown;   # settle the waiter now, not in global destruction

    is transport_with($flavour, [ $static->() ])->pool->max_size, 5,
      "$flavour: without pool_size beside the broker the pool keeps its default";
  }

  # -------------------------------------------------------------------------
  # 5. Auto-reconnect beside the broker.
  # -------------------------------------------------------------------------

  {
    my $s = transport_with($flavour, [ $static->(), { $reconnect => 1 } ]);
    is_deeply spawn($s), [ $dsn, 'app', 's3cret', { %FORCED, $reconnect => 1 } ],
      "$flavour: $reconnect => 1 beside the broker is respected on a pool connection";
    is_deeply open_listen($s), [ $dsn, 'app', 's3cret', { %FORCED, $reconnect => 0 } ],
      '... and forced off on the listen connection all the same';

    # The broker answers the OTHER DBD's DSN (karr k60: the class does not
    # decide the DBD). The caller names that DBD's attribute; this class must
    # not add its own name beside it -- DBD::MariaDB refuses a mysql_* one.
    my $o = $FLAVOUR{ $f->{other} };
    my $x = transport_with($flavour, [
      $vault->(-dsn => "dbi:$f->{other}:dbname=appdb"), { $o->{reconnect} => 1 },
    ]);
    is_deeply eval { spawn($x) },
      [ "dbi:$f->{other}:dbname=appdb", 'vault-user', 'vault-pw', { %FORCED, $o->{reconnect} => 1 } ],
      "$flavour class, a dbi:$f->{other}: answer: $o->{reconnect} beside the broker is respected, $reconnect not added"
      or diag $@;
  }

  # -------------------------------------------------------------------------
  # 6. What the owner applies keeps working beside backend settings.
  # -------------------------------------------------------------------------

  {
    my $schema = $f->{schema}->connect($static->(), {
      async => 'future_io', $timeout => 7, pool_size => 2,
      quote_names => 1, on_connect_do => [ 'SET @k64 = 1' ],
    });
    my $storage = $schema->storage;
    is $storage->_sql_maker_opts->{quote_names}, 1,
      "$flavour: quote_names beside the broker is applied by the owning storage";
    is_deeply $storage->on_connect_do, [ 'SET @k64 = 1' ],
      '... and on_connect_do is kept there';

    my $async = eval { $storage->async } or diag $@;
    SKIP: {
      skip 'no backend', 2 unless $async;
      is_deeply eval { spawn($async) },
        [ $dsn, 'app', 's3cret', { $timeout => 7, %FORCED, $reconnect => 0 } ],
        '... the pool connection gets the DBD attribute and none of the owner-side options'
        or diag $@;
      # the session statement first, then what the owner replays (karr k121)
      is_deeply $CONNECTS[-1]{dbh}{did},
        [ DBIO::MySQL::Storage::strict_sql_mode_statement(), 'SET @k64 = 1' ],
        '... and the owner replays on_connect_do on it, after the session statement';
    }
  }

  # -------------------------------------------------------------------------
  # 7. DBI form without a broker: the fifth element.
  # -------------------------------------------------------------------------

  {
    my $s = $f->{async}->new(undef);
    $s->connect_info([ "dbi:$dbd:dbname=appdb", 'u', 'p',
      { $multi => 1, $timeout => 30, pool_size => 4 },
      { $timeout => 7, pool_size => 2, async => 'future_io',
        on_connect_do => [ 'SET @k64 = 1' ], quote_names => 1 },
    ]);
    my $want = [ "dbi:$dbd:dbname=appdb", 'u', 'p',
                 { $multi => 1, $timeout => 7, %FORCED, $reconnect => 0 } ];
    is_deeply spawn($s), $want,
      "$flavour, DBI form: attributes in the fifth element reach a pooled connection, the fifth winning, nothing DBIO-private";
    is_deeply open_listen($s), $want, '... and the listen connection';
    is $s->pool->max_size, 2, '... and pool_size in the fifth element sizes the pool, winning over the fourth';
  }

  {
    my $s = $f->{async}->new(undef);
    $s->connect_info([ "dbi:$dbd:dbname=appdb", 'u', 'p', undef, { $timeout => 7 } ]);
    is_deeply spawn($s), [ "dbi:$dbd:dbname=appdb", 'u', 'p', { $timeout => 7, %FORCED, $reconnect => 0 } ],
      "$flavour, DBI form: a fifth element without a fourth is read too";
    is $s->pool->max_size, 5, '... the pool keeping its default size';
  }

  # Auto-reconnect: one set in the fifth element is the caller's choice just
  # like one in the fourth (ADR 0005), and the fifth wins there too.
  {
    my $on = $f->{async}->new(undef);
    $on->connect_info([ "dbi:$dbd:dbname=appdb", 'u', 'p', {}, { $reconnect => 1 } ]);
    is spawn($on)->[3]{$reconnect}, 1,
      "$flavour, DBI form: $reconnect => 1 in the fifth element is respected on a pool connection";
    is open_listen($on)->[3]{$reconnect}, 0, '... and forced off on the listen connection';

    my $off = $f->{async}->new(undef);
    $off->connect_info([ "dbi:$dbd:dbname=appdb", 'u', 'p', { $reconnect => 1 }, { $reconnect => 0 } ]);
    is spawn($off)->[3]{$reconnect}, 0,
      "$flavour, DBI form: $reconnect => 0 in the fifth element wins over 1 in the fourth";
  }

  # Through a schema, against what the owning sync storage made of the same
  # two hashes: the pooled connection must not see a different value than the
  # owner's own connection would.
  {
    my $schema = $f->{schema}->connect("dbi:$dbd:dbname=appdb", 'u', 'p',
      { async => 'future_io', $multi => 1, $timeout => 30 },
      { $timeout => 7, pool_size => 2 });
    my $owner_attrs = $schema->storage->_dbi_connect_info->[3];
    is_deeply [ @{$owner_attrs}{ $multi, $timeout } ], [ 1, 7 ],
      "$flavour, through a schema: the owning sync storage lets the fifth element win";
    ok !exists $owner_attrs->{pool_size}, '... and keeps pool_size out of its own connect';

    my $async = $schema->storage->async;
    my $got   = spawn($async);
    is_deeply [ @{ $got->[3] }{ $multi, $timeout } ], [ @{$owner_attrs}{ $multi, $timeout } ],
      '... and a pooled connection gets the very values the owner has';
    is_deeply $got, [ "dbi:$dbd:dbname=appdb", 'u', 'p', { $multi => 1, $timeout => 7, %FORCED, $reconnect => 0 } ],
      '... and nothing else beside the forced connect shape';
    is $async->pool->max_size, 2, '... and pool_size in the fifth element sizes the pool';
  }

  # The component pins the class for every DSN (karr k60): the other DBD's
  # DSN on this flavour's schema, its auto-reconnect in the fifth element.
  {
    my $o = $FLAVOUR{ $f->{other} };
    my $schema = $f->{schema}->connect("dbi:$f->{other}:dbname=appdb", 'u', 'p',
      { async => 'future_io' }, { $o->{reconnect} => 1 });
    my $async = $schema->storage->async;
    isa_ok $async, $f->{async}, "$flavour schema over a dbi:$f->{other}: DSN: the backend";
    is_deeply eval { spawn($async) },
      [ "dbi:$f->{other}:dbname=appdb", 'u', 'p', { %FORCED, $o->{reconnect} => 1 } ],
      "... $o->{reconnect} => 1 in the fifth element is respected, $reconnect not added"
      or diag $@;
  }
}

done_testing;
