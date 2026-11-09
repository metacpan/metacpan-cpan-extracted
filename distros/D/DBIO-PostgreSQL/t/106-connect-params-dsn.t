use strict;
use warnings;
use Test::More;

# OFFLINE test: connection parameters given by value go into a dbi:Pg: DSN by
# one rule, on the sync storage and on the future_io transport alike
# (karr k102).
#
# WHY: a schema is connected with connection parameters instead of a DSN --
# dbname, host and port, as DBIO::AccessBroker::Static answers them, or a
# connect-info hash with a dbname and no dsn. Core builds the DSN through the
# driver storage's seam _connect_params_dsn (ADR 0057), and its default writes
# key=value as given. Between that text and the value stand two readers:
# DBD::Pg, which edits the DSN as text, and libpq, which ends a bare value at
# a blank and reads a backslash as an escape. So on the sync storage a value
# was a value only while it held none of that:
#   * dbname 'my db' did not connect at all (libpq: missing "=" after "db");
#   * dbname 'app sslmode=disable' set sslmode -- any libpq parameter could
#     be put in behind a name, hostaddr among them;
#   * dbname q{it's} opened the quote DBD::Pg ends a parameter at: the host
#     behind it became part of the name, and libpq went to its default socket
#     with the credentials given for that host;
#   * dbname 'back\slash' asked for backslash, dbname '"app"' for app.
# The future_io transport has written every value through one rule since karr
# k80/k96, so the two connections of one schema could name different
# databases. The rule is now DBIO::PostgreSQL::Util::quote_dsn_value, and both
# write through it.
#
# What this file claims:
#   1. quote_dsn_value writes a value so that it survives both readers: bare
#      where nothing touches it, otherwise single-quoted with ', \ and =
#      escaped; an empty value is '' (bare it would take the next parameter
#      for its value); undef, a reference and a NUL are refused, the value
#      never named;
#   2. the sync seam writes dbname, host and port through it, in core's order,
#      leaving out what is not given;
#   3. for the same parameters the sync storage -- from a connect-info hash
#      and from a Static broker -- and the future_io transport hold the very
#      same DSN, and the two halves of one schema do;
#   4. the real DBD::Pg and libpq read a host written by the sync storage as
#      it was given: the socket directory libpq tries is the value;
#   5. a reference and a NUL are refused on the sync storage as on future_io,
#      naming the parameter and never the value, and DBI->connect is not
#      reached.
#
# NOT CLAIMED HERE: a ';' in a value. Core refuses it before the seam is asked
# (ADR 0057), so the sync storage does not connect with one while future_io
# does; section 2 shows the seam would write it right.
#
# WHAT RUNS FOR REAL: core's connect-info normalisation and broker attach,
# this dist's seams, and in 4 DBI, DBD::Pg and libpq up to a failing
# connect(2) on a unix socket directory that does not exist.
# THE SUBSTITUTION: none in 1-4. In 5, DBI->connect counts its calls.

use DBI;
use DBD::Pg;
use DBIO::Util ();
use DBIO::AccessBroker::Static;
use DBIO::PostgreSQL::Storage;
use DBIO::PostgreSQL::Util ();

my $HAVE_FUTURE_IO = eval { require DBIO::PostgreSQL::Storage::Async; 1 };
my $NO_FUTURE_IO   = 'DBIO::Async not installed (recommends only) -- future_io transport unavailable';

{
  package K102::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('PostgreSQL');
}

my $quote = sub { DBIO::PostgreSQL::Util::quote_dsn_value(@_) };

# ---------------------------------------------------------------------------
# 1. The rule.
# ---------------------------------------------------------------------------

ok eval { DBIO::PostgreSQL::Util->import('quote_dsn_value'); 1 },
  'DBIO::PostgreSQL::Util exports quote_dsn_value on request'
  or diag $@;

for my $case (
  [ 'a plain name',                       'appdb',                 'appdb' ],
  [ 'a number',                           5433,                    '5433' ],
  [ 'a host name',                        'db-1.example.org',      'db-1.example.org' ],
  [ 'a socket directory',                 '/var/run/postgresql',   '/var/run/postgresql' ],
  [ 'an IPv6 address',                    '2001:db8::1',           '2001:db8::1' ],
  [ 'an IPv6 address with a zone',        'fe80::1%eth0',          'fe80::1%eth0' ],
  [ 'a host list',                        'db1.example,db2.example', 'db1.example,db2.example' ],
  [ 'a blank',                            'my db',                 q{'my db'} ],
  [ 'a tab and a newline',                "a\tb\nc",               qq{'a\tb\nc'} ],
  [ 'an apostrophe',                      q{it's},                 q{'it\\'s'} ],
  [ 'a backslash',                        'back\\slash',           q{'back\\\\slash'} ],
  [ q{a '=' (DBD::Pg rewrites on one)},   'a=b',                   q{'a\\=b'} ],
  [ 'double quotes: part of the value',   '"app"',                 q{'"app"'} ],
  [ q{a ';'},                             'a;b',                   q{'a;b'} ],
  [ 'a parameter behind the value',       'app hostaddr=192.0.2.1', q{'app hostaddr\\=192.0.2.1'} ],
  [ 'an empty value',                     '',                      q{''} ],
) {
  my ($label, $value, $want) = @$case;
  is scalar eval { $quote->($value) }, $want, "quote_dsn_value, $label"
    or diag $@;
}

for my $case (
  [ 'an undefined value', undef ],
  [ 'a reference',        [ 'hunter2' ] ],
  [ 'a value with a NUL', "hunter2\0x" ],
) {
  my ($label, $value) = @$case;
  my $ok  = eval { $quote->($value); 1 };
  my $err = $@;
  ok !$ok, "quote_dsn_value refuses $label";
  like $err, qr/connection parameter value/, '... saying what it was asked to write';
  unlike $err, qr/hunter2|ARRAY/, '... and not the value';
}

# ---------------------------------------------------------------------------
# 2. The sync seam.
# ---------------------------------------------------------------------------

for my $case (
  [ 'plain parts, in core\'s order',
    { port => 5433, host => 'db.example', dbname => 'appdb' },
    'dbi:Pg:dbname=appdb;host=db.example;port=5433' ],
  [ 'a part not given is left out',
    { host => 'db.example' },
    'dbi:Pg:host=db.example' ],
  [ 'each part is written by the rule',
    { dbname => 'my db', host => q{/tmp/it's}, port => '5433 sslmode=disable' },
    q{dbi:Pg:dbname='my db';host='/tmp/it\\'s';port='5433 sslmode\\=disable'} ],
  [ q{a ';', were core to pass one on},
    { dbname => 'a;b', host => 'db.example' },
    q{dbi:Pg:dbname='a;b';host=db.example} ],
) {
  my ($label, $params, $want) = @$case;
  is scalar eval { DBIO::PostgreSQL::Storage->_connect_params_dsn('Pg', $params) }, $want,
    "_connect_params_dsn, $label"
    or diag $@;
}

# ---------------------------------------------------------------------------
# 3. One DSN for the same parameters, whichever way they come.
# ---------------------------------------------------------------------------

sub sync_hash_dsn {
  my (%param) = @_;
  return K102::Schema->connect({ %param, user => 'app', password => 's3cret' })
    ->storage->_dbi_connect_info->[0];
}

sub static_broker {
  my (%param) = @_;
  return DBIO::AccessBroker::Static->new(%param, username => 'app', password => 's3cret');
}

sub sync_broker_dsn {
  return K102::Schema->connect(static_broker(@_))->storage->_dbi_connect_info->[0];
}

sub future_io_dsn {
  my $s = DBIO::PostgreSQL::Storage::Async->new(undef);
  $s->connect_info([ static_broker(@_) ]);
  return $s->_async_broker_conninfo('write')->{dsn};
}

my @SERVER = (host => 'db.example', port => 5433);
my $TAIL   = ';host=db.example;port=5433';

for my $case (
  [ 'a plain name',
    { dbname => 'appdb', @SERVER },                  "dbi:Pg:dbname=appdb$TAIL" ],
  [ 'a blank in the name',
    { dbname => 'my db', @SERVER },                  "dbi:Pg:dbname='my db'$TAIL" ],
  [ 'a name in double quotes: they are part of it',
    { dbname => '"appdb"', @SERVER },                qq{dbi:Pg:dbname='"appdb"'$TAIL} ],
  [ 'an apostrophe: the host behind it stays a parameter',
    { dbname => q{it's}, @SERVER },                  qq{dbi:Pg:dbname='it\\'s'$TAIL} ],
  [ 'a backslash',
    { dbname => 'back\\slash', @SERVER },            qq{dbi:Pg:dbname='back\\\\slash'$TAIL} ],
  [ q{a '='},
    { dbname => 'a=b', @SERVER },                    qq{dbi:Pg:dbname='a\\=b'$TAIL} ],
  [ q{'db=' in the name: no second dbname},
    { dbname => 'app-db=1', @SERVER },               qq{dbi:Pg:dbname='app-db\\=1'$TAIL} ],
  [ 'a libpq parameter behind the name is part of the name',
    { dbname => 'appdb hostaddr=192.0.2.1', @SERVER },
    qq{dbi:Pg:dbname='appdb hostaddr\\=192.0.2.1'$TAIL} ],
  [ 'a tab',
    { dbname => "tab\tbed", @SERVER },               qq{dbi:Pg:dbname='tab\tbed'$TAIL} ],
  [ 'an IPv6 host',
    { dbname => 'appdb', host => '2001:db8::1', port => 5433 },
    'dbi:Pg:dbname=appdb;host=2001:db8::1;port=5433' ],
  [ 'a host with a blank and a port with a parameter behind it',
    { dbname => 'appdb', host => '/tmp/my sockets', port => '5433 sslmode=disable' },
    q{dbi:Pg:dbname=appdb;host='/tmp/my sockets';port='5433 sslmode\\=disable'} ],
) {
  my ($label, $param, $want) = @$case;

  my $sync = eval { sync_hash_dsn(%$param) };
  is $sync, $want, "$label: the sync storage, from a connect-info hash"
    or diag $@;
  is scalar eval { sync_broker_dsn(%$param) }, $want, '... the sync storage, from a Static broker'
    or diag $@;

  SKIP: {
    skip $NO_FUTURE_IO, 1 unless $HAVE_FUTURE_IO;
    is scalar eval { future_io_dsn(%$param) }, $sync, '... and future_io holds the very same DSN'
      or diag $@;
  }
}

# An empty dbname names no database: the core refuses it (core karr k340)
# instead of building a DSN without one, whichever way it comes.
{
  my %param = (dbname => '', @SERVER);
  my $refused = sub {
    my ($code, $label) = @_;
    my $dsn = eval { $code->() };
    like $@, qr/empty dbname/, $label;
  };
  $refused->(sub { sync_hash_dsn(%param) },
    'an empty dbname is refused: the sync storage, from a connect-info hash');
  $refused->(sub { sync_broker_dsn(%param) }, '... the sync storage, from a Static broker');
  SKIP: {
    skip $NO_FUTURE_IO, 1 unless $HAVE_FUTURE_IO;
    $refused->(sub { future_io_dsn(%param) }, '... and future_io');
  }
}

SKIP: {
  skip $NO_FUTURE_IO, 2 unless $HAVE_FUTURE_IO;
  my $schema = K102::Schema->connect(
    static_broker(dbname => '"my db"', @SERVER), { async => 'future_io' },
  );
  my $sync  = $schema->storage->_dbi_connect_info->[0];
  my $async = eval { $schema->storage->async->_async_broker_conninfo('write')->{dsn} };
  is $sync, qq{dbi:Pg:dbname='"my db"'$TAIL},
    'one schema, a Static broker and { async => future_io }: the sync half holds the name as given';
  is $async, $sync, '... and its future_io backend the same DSN -- the two cannot name different databases'
    or diag $@;
}

# ---------------------------------------------------------------------------
# 4. The real DBD::Pg and libpq, without a server: the host libpq reads.
#
# A connect to a unix socket directory that does not exist fails in
# connect(2), and libpq's error names the socket path it tried -- the host as
# libpq read it. Every host below is under that directory and names no other
# way out (no ';', no hostaddr, no service), written right or wrong; the DSN
# is looked at before it is used all the same.
# ---------------------------------------------------------------------------

my $DEAD = '/nonexistent/dbio-postgresql-k102';

# The socket directory in libpq's own words -- socket "<dir>/.s.PGSQL.<port>"
# -- and not the DSN that DBI repeats in front of them.
sub socket_dir_tried {
  my ($error) = @_;
  return defined $error && $error =~ m{socket "(\Q$DEAD\E.*?)/\.s\.PGSQL\.\d+"}s ? $1 : undef;
}

# The socket directory libpq tried for a sync connect with this host.
sub sync_host_as_libpq_read_it {
  my ($host) = @_;
  delete local @ENV{ grep { /^PG/ } keys %ENV };

  my $schema = K102::Schema->connect({
    dbname => 'appdb', host => $host, user => 'app', password => 's3cret',
  });
  my $dsn = $schema->storage->_dbi_connect_info->[0];
  BAIL_OUT("a DSN of this file may lead somewhere else than $DEAD")
    unless $dsn =~ m{\Adbi:Pg:dbname=appdb;host='?\Q$DEAD\E/} && $dsn !~ /hostaddr|service/;

  if (eval { $schema->storage->dbh; 1 }) {
    $schema->storage->disconnect;
    BAIL_OUT('a connection was opened -- this file must never reach a server');
  }
  return socket_dir_tried("$@");
}

SKIP: {
  skip "$DEAD exists on this machine", 8 if -e $DEAD;

  for my $value (
    'plain',
    'x db=1',
    'my database = prod',
    'a=b',
    'say "hi"',
    'dbname = "y"',
    q{it's here},
    'back\\slash',
  ) {
    my $host = "$DEAD/$value";
    is sync_host_as_libpq_read_it($host), $host,
      "libpq itself reads [$value] as the sync storage was given it";
  }
}

# An empty value. Written bare, libpq skips the blank behind the '=' and takes
# the next parameter for the value -- the host here, and it would go to its
# default one. So the real libpq is asked only once the rule writes it quoted.
SKIP: {
  my $empty = eval { $quote->('') } // '';
  skip "$DEAD exists on this machine", 1 if -e $DEAD;
  skip 'quote_dsn_value does not write an empty value quoted', 1 unless $empty eq q{''};

  delete local @ENV{ grep { /^PG/ } keys %ENV };
  my $dbh = DBI->connect("dbi:Pg:application_name=$empty;host=$DEAD/behind", 'app', 's3cret',
    { RaiseError => 0, PrintError => 0 });
  if ($dbh) {
    $dbh->disconnect;
    BAIL_OUT('a connection was opened -- this file must never reach a server');
  }
  is socket_dir_tried($DBI::errstr), "$DEAD/behind",
    'libpq itself reads the parameter behind an empty value written by the rule';
}

# ---------------------------------------------------------------------------
# 5. What no connection string can carry.
# ---------------------------------------------------------------------------

{
  my $connects = 0;
  no warnings 'redefine';
  local *DBI::connect = sub { $connects++; die "DBI->connect was reached\n" };

  for my $case (
    [ 'a reference as dbname', 'dbname', qr/is a reference/,
      { dbname => [ 'inside' ], host => 'db.example' } ],
    [ 'a NUL in the host',     'host',   qr/contains a NUL/,
      { dbname => 'appdb', host => "db.example\0inside" } ],
    [ 'a NUL in the dbname',   'dbname', qr/contains a NUL/,
      { dbname => "appdb\0inside", host => 'db.example' } ],
  ) {
    my ($label, $key, $why, $param) = @$case;

    for my $way (
      [ 'a connect-info hash',
        sub { K102::Schema->connect({ %$param, user => 'app', password => 'hunter2' })->storage->dbh } ],
      [ 'a Static broker',
        sub { K102::Schema->connect(
          DBIO::AccessBroker::Static->new(%$param, username => 'app', password => 'hunter2'),
        )->storage->dbh } ],
    ) {
      my ($from, $code) = @$way;
      $connects = 0;
      my $ok  = eval { $code->(); 1 };
      my $err = $@;
      ok !$ok, "$label, from $from: the sync storage does not connect";
      like $err, qr/connection parameter '$key'/, '... naming the parameter';
      like $err, $why, '... and what is wrong with its value';
      unlike $err, qr/inside|hunter2|ARRAY\(/, '... never the value, nor the password';
      is $connects, 0, '... and nothing was sent to DBI->connect';
    }
  }
}

done_testing;
