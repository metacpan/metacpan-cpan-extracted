#!/usr/bin/env perl
# t/47-disconnect-releases-file-lock.t -- a disconnected storage gives the
# database file back (karr k25).
#
# WHY this matters: DuckDB takes an exclusive lock on a read-write database
# file at connect, and a second process cannot open the file -- not even
# read-only -- while it is held. Handing a database from one long-lived
# process to another therefore depends on disconnect actually releasing it.
# DBD::DuckDB 0.16 never frees a prepared statement, the statement keeps the
# database instance alive, and the lock outlives the handle until the process
# ends. DBIO::DuckDB::Storage frees the statements itself; this file pins
# that the lock really goes away, by the only two observations that can see
# it:
#
#   - a SECOND PROCESS opening the file through DBI (portable, the assertion
#     that counts), and
#   - /proc/locks, read for this process's lock on the file (Linux only).
#
# Deliberately NOT used: opening the file from this process. A POSIX advisory
# lock does not stop open(), so such a probe reports "free" for a locked file
# -- and closing ANY descriptor on a file drops the process's own locks on it,
# so the probe would also destroy what it measures.

use strict;
use warnings;
use Test::More;
use DBI;
use File::Temp ();
use DBIO::Util qw(file_path slurp_file);
use DBIO::DuckDB::Storage;
use DBIO::DuckDB::Test;
use DBIO::Test::Schema;

# ---- the two probes ----------------------------------------------------

my $PROBE = <<'EOP';
my $dbh = DBI->connect("dbi:DuckDB:dbname=$ARGV[0]", '', '',
  { RaiseError => 0, PrintError => 0 });
if ($dbh) { $dbh->disconnect; exit 0 }
exit( (DBI->errstr // '') =~ /lock/i ? 3 : 4 );
EOP

# 'opened' / 'locked', as seen by a separate perl process.
sub second_process {
  my ($file) = @_;
  my $rc = system($^X, '-MDBI', '-e', $PROBE, $file);
  die "could not run the probe process: $!" if $rc == -1;
  return 'probe died of signal ' . ($rc & 127) if $rc & 127;
  my $exit = $rc >> 8;
  return $exit == 0 ? 'opened'
       : $exit == 3 ? 'locked'
       :              "probe failed for an unrelated reason (exit $exit)";
}

# 'locked' / 'free' from /proc/locks: lines carrying this pid and the file's
# inode. Returns undef where /proc/locks does not exist.
sub proc_locks {
  my ($file) = @_;
  return undef unless -r '/proc/locks';
  my $inode = (stat $file)[1];
  for my $line (split /\n/, slurp_file('/proc/locks')) {
    my @f = split ' ', $line;
    next unless @f >= 6 and $f[4] == $$;
    return 'locked' if $f[5] =~ /:(\d+)\z/ and $1 == $inode;
  }
  return 'free';
}

# Decided by the baseline below: /proc/locks counts only where it is seen to
# report the lock a second process is refused by.
my $PROC_LOCKS_USABLE = 0;

sub lock_is {
  my ($file, $want, $name) = @_;
  local $Test::Builder::Level = $Test::Builder::Level + 1;
  is second_process($file), ($want eq 'locked' ? 'locked' : 'opened'),
    "$name -- second process";
  SKIP: {
    skip '/proc/locks does not show DuckDB file locks on this platform', 1
      unless $PROC_LOCKS_USABLE;
    is proc_locks($file), $want, "$name -- /proc/locks";
  }
}

my $tmp = File::Temp->newdir;
my $n   = 0;

sub fresh_file { file_path($tmp, 'k25-' . ++$n . '.duckdb') }

sub schema_on {
  my ($file, %args) = @_;
  return DBIO::DuckDB::Test->init_schema(dsn => "dbi:DuckDB:dbname=$file", %args);
}

# ---- baseline: the probes can see both states --------------------------
# Without this, every "free" below could come from a probe that sees nothing.
{
  my $file   = fresh_file();
  my $schema = schema_on($file, no_deploy => 1);
  $schema->storage->ensure_connected;

  is second_process($file), 'locked',
    'a connected read-write storage holds the file: a second process is refused';

  $PROC_LOCKS_USABLE = (proc_locks($file) // '') eq 'locked' ? 1 : 0;
  note $PROC_LOCKS_USABLE
    ? '/proc/locks shows the lock -- asserting on it as well'
    : '/proc/locks unavailable or blind to this lock -- second-process probe only';

  $schema->storage->disconnect;
  lock_is $file, 'free', 'no statement run: disconnect releases the file';
}

# ---- the claim: statements have run, disconnect still releases ---------

# Deploy and populate: DDL through $dbh->do, transactions, inserts with
# RETURNING, whose statement handles core finishes.
{
  my $file   = fresh_file();
  my $schema = schema_on($file);

  my $artist = $schema->resultset('Artist')->create({ name => 'Autechre' });
  $schema->resultset('CD')->create({
    artist => $artist->artistid, title => 'Tri Repetae', year => 1995,
  });
  my $cd = $schema->resultset('CD')->search(
    { 'me.title' => 'Tri Repetae' },
    { prefetch => 'artist' },
  )->single;
  is $cd->artist->name, 'Autechre', 'the database was really used';

  lock_is $file, 'locked', 'deployed and queried: held while connected';
  $schema->storage->disconnect;
  lock_is $file, 'free', 'deployed and queried: disconnect releases the file';

  # The storage reconnects on demand; the second connection is covered too.
  ok $schema->resultset('Artist')->count, 'the schema reconnected by itself';
  $schema->storage->disconnect;
  lock_is $file, 'free', 'after a reconnect: disconnect releases the file again';
}

# A schema that names no driver never gets as far as a file: it is refused at
# connect, before a storage is built (core ADR 0067). There is no storage
# that starts generic and becomes the DuckDB storage on the first handle.
SKIP: {
  skip 'core predates ADR 0067 (no refusal of a schema without a driver)', 2
    unless DBIO->can('driver_for');

  my $file = fresh_file();
  my $err  = do {
    local $@;
    eval { DBIO::Test::Schema->clone->connect("dbi:DuckDB:dbname=$file"); 1 } ? '' : "$@";
  };
  like $err, qr/declares no driver.*ADR 0067/s,
    'a schema that names no driver is refused at connect';
  ok !-e $file, 'and the database file was never opened';
}

# Transactions, the committing and the rolling-back kind. The rollback path
# runs this storage's own $dbh->do('ROLLBACK') (ADR 0005).
{
  my $file   = fresh_file();
  my $schema = schema_on($file);

  $schema->txn_do(sub { $schema->resultset('Artist')->create({ name => 'committed' }) });

  # The second transaction has to get as far as its own die. Its insert is
  # the statement the first one ran, and an insert that fails rolls back too:
  # "the row is gone" holds either way, so the exception is looked at (k33).
  my $err = do {
    local $@;
    eval {
      $schema->txn_do(sub {
        $schema->resultset('Artist')->create({ name => 'rolled back' });
        die "the block gives up\n";
      });
      1;
    } ? '' : "$@";
  };
  like $err, qr/the block gives up/,
    'the second transaction ran its insert and ended in its own exception';
  is $schema->resultset('Artist')->search({ name => 'committed' })->count, 1,
    'the committed row is there';
  is $schema->resultset('Artist')->search({ name => 'rolled back' })->count, 0,
    'the rolled-back row is gone';

  $schema->storage->disconnect;
  lock_is $file, 'free', 'commit and rollback: disconnect releases the file';
}

# Statement handles the caller drives by hand through dbh_do: one finished
# explicitly, one simply dropped, and $dbh->do, which never calls finish.
{
  my $file   = fresh_file();
  my $schema = schema_on($file, no_deploy => 1);

  $schema->storage->dbh_do(sub {
    my ($storage, $dbh) = @_;
    $dbh->do('CREATE TABLE t (i INTEGER)');
    $dbh->do('INSERT INTO t VALUES (1), (2)');

    my $finished = $dbh->prepare('SELECT i FROM t ORDER BY i');
    $finished->execute;
    1 while $finished->fetchrow_arrayref;
    $finished->finish;

    my $dropped = $dbh->prepare('SELECT i FROM t');
    $dropped->execute;

    my $never_run = $dbh->prepare('SELECT 1');
    return;
  });

  $schema->storage->disconnect;
  lock_is $file, 'free', 'hand-driven handles: disconnect releases the file';
}

# A statement DuckDB refuses still allocates a prepared statement.
{
  my $file   = fresh_file();
  my $schema = schema_on($file, no_deploy => 1);

  my $err = do {
    local $@;
    eval { $schema->storage->dbh_do(sub { $_[1]->do('SELEKT nonsense') }); 1 } ? '' : "$@";
  };
  like $err, qr/syntax error/i, 'the bad statement was refused by DuckDB';

  $schema->storage->disconnect;
  lock_is $file, 'free', 'failed prepare: disconnect releases the file';
}

# ---- the boundary: a live statement handle keeps the database open -----
# disconnect closes the connection, but DuckDB keeps the database instance
# for as long as a prepared statement exists. The file is released when the
# last handle goes, not before -- which is what the README tells users.
{
  my $file   = fresh_file();
  my $schema = schema_on($file);

  my $cursor = $schema->resultset('Artist')->search({}, { order_by => 'artistid' })->cursor;
  ok $cursor->next, 'cursor is mid-iteration';

  $schema->storage->disconnect;
  lock_is $file, 'locked', 'open cursor: still held after disconnect';

  undef $cursor;
  lock_is $file, 'free', 'open cursor: released once the cursor is gone';
}

# ---- callbacks the application installed keep working ------------------
# The release is a DBI per-handle callback, so it shares $dbh->{Callbacks}
# with whatever the application put there.
{
  my $file = fresh_file();
  my %seen = (execute => 0, finish => 0, DESTROY => 0, prepare => 0);

  my $schema = schema_on($file,
    no_deploy    => 1,
    connect_opts => {
      RaiseError => 1, PrintError => 0,
      Callbacks  => {
        prepare        => sub { $seen{prepare}++; return },
        ChildCallbacks => {
          execute => sub { $seen{execute}++; return },
          finish  => sub { $seen{finish}++;  return },
          DESTROY => sub { $seen{DESTROY}++; return },
        },
      },
    },
  );

  $schema->storage->dbh_do(sub {
    my $sth = $_[1]->prepare('SELECT 42');
    $sth->execute;
    $sth->finish;
    return;
  });

  $schema->storage->disconnect;

  ok $seen{$_}, "the application's own $_ callback fired"
    for qw(prepare execute finish DESTROY);
  lock_is $file, 'free', 'with application callbacks: disconnect releases the file';
}

# ---- the release is bound to the DBD::DuckDB releases it was read against
# It frees memory DBD::DuckDB owns, so it must not run against a release
# nobody has read: there the storage installs nothing and that release's own
# behaviour shows. (Asserted on the callback, not on the lock, so that this
# holds for a later release whether or not it still leaks.)
for my $case ([ '0.16' => 1 ], [ '0.17' => 0 ]) {
  my ($version, $installed) = @$case;

  no warnings 'once';
  local $DBD::DuckDB::VERSION = $version;

  my $schema = schema_on(fresh_file(), no_deploy => 1);
  my $cb     = $schema->storage->dbh->{Callbacks};

  is +( $cb && $cb->{ChildCallbacks}{DESTROY} ? 1 : 0 ), $installed,
    "DBD::DuckDB $version: statement release "
      . ($installed ? 'installed' : 'not installed');

  $schema->storage->disconnect;
}

# ---- upstream sentinel -------------------------------------------------
# A plain DBI handle, no DBIO: the leak itself. When this starts to pass,
# DBD::DuckDB has been fixed and the release in DBIO::DuckDB::Storage can go
# (see docs/upstream/).
{
  my $file = fresh_file();
  my $dbh  = DBI->connect("dbi:DuckDB:dbname=$file", '', '',
    { RaiseError => 1, PrintError => 0 });
  $dbh->do('CREATE TABLE t (i INTEGER)');
  $dbh->disconnect;
  undef $dbh;

  TODO: {
    local $TODO = 'DBD::DuckDB 0.16 never frees a prepared statement (karr k25)';
    is second_process($file), 'opened',
      'plain DBD::DuckDB: disconnect releases the file';
  }
}

done_testing;
