use strict;
use warnings;
use Test::More;
use POSIX qw(WNOHANG);
use IO::Select;
use File::Temp ();

# LIVE test: what the offline fakes of t/07 to t/09 cannot show (karr k18) --
# the forked transport against a real DBD handle, a real lock and real
# resource limits. Two databases are driven when present:
#
#   SQLite   in-process, a file database (DBD::SQLite + dbio-sqlite)
#   PG       DBIO_TEST_PG_DSN (+ _USER/_PASS), through dbio-postgresql
#
# Each is skipped on its own -- no DBD, no driver dist, no DSN -- so the
# default suite keeps its dependency-free posture (ADR 0001). The tests are
# the parts of the plan that can be run against those two; the vault leases
# of k18 point 3 need a vault and are not here.
#
# Every table carries the prefix forkedlive_<backend>_<pid> and is dropped
# again at the end.
#
# WHAT RUNS FOR REAL: fork + pipe + Storable, DBIO::Forked::Storage and its
# Future, the driver's sync storage as the owner in the child, a real DBD
# handle in the parent, real row locks, real RLIMIT_NOFILE / RLIMIT_NPROC
# (a subprocess started through `ulimit`).
# THE SUBSTITUTION: none of the database. The broker of section 3 is a
# DBIO::AccessBroker::Static that dies on request in a child.

use DBIO::Forked;
use DBIO::Forked::Future;
use DBIO::AccessBroker::Static;
use DBIO::Storage::Async;

my %backend;

if (eval { require DBD::SQLite; require DBIO::SQLite::Storage; 1 }) {
  my $dir = File::Temp->newdir;
  $backend{sqlite} = {
    dir  => $dir,
    dsn  => 'dbi:SQLite:dbname=' . $dir->dirname . '/forkedlive.db',
    user => '',
    pass => '',
    comp => 'SQLite',
    # DBD::SQLite waits 30 s for a lock by default; a short wait keeps the
    # "database is locked" answer of section 1 quick
    on_connect_do => [ 'PRAGMA busy_timeout = 300' ],
  };
}

if ($ENV{DBIO_TEST_PG_DSN}
    && eval { require DBD::Pg; require DBIO::PostgreSQL::Storage; 1 }) {
  $backend{pg} = {
    dsn  => $ENV{DBIO_TEST_PG_DSN},
    user => $ENV{DBIO_TEST_PG_USER} // '',
    pass => $ENV{DBIO_TEST_PG_PASS} // '',
    comp => 'PostgreSQL',
  };
}

plan skip_all => 'neither DBD::SQLite + dbio-sqlite nor DBIO_TEST_PG_DSN + DBD::Pg + dbio-postgresql available -- skipping live transport tests'
  unless %backend;

plan skip_all => 'no fork on this platform' if $^O eq 'MSWin32';

alarm 240;   # the whole file; every wait below has a bound of its own

# The result and schema classes, as source text: the subprocesses of
# section 2 build the same ones.
sub defs {
  my ($pkg, $table, $comp) = @_;
  return <<"EOF";
package ${pkg}::Row;
use base 'DBIO::Core';
__PACKAGE__->table('$table');
__PACKAGE__->add_columns(
  id  => { data_type => 'integer' },
  val => { data_type => 'varchar', size => 50 },
);
__PACKAGE__->set_primary_key('id');
package ${pkg}::Schema;
use base 'DBIO::Schema';
__PACKAGE__->load_components('$comp');
__PACKAGE__->register_class(Row => '${pkg}::Row');
1;
EOF
}

sub connect_args {
  my ($b, @extra) = @_;
  return (
    $b->{dsn}, $b->{user}, $b->{pass},
    { async => 'forked', AutoCommit => 1, RaiseError => 1,
      ($b->{on_connect_do} ? (on_connect_do => $b->{on_connect_do}) : ()),
      @extra },
  );
}

sub flat { my $m = join ' ', @_; $m =~ s/\s+/ /g; $m =~ s/^ | $//g; return $m }

# Read lines from $fh until one matches $until or $seconds pass.
sub read_lines {
  my ($fh, $until, $seconds) = @_;
  my $sel      = IO::Select->new($fh);
  my $deadline = time + $seconds;
  my ($buf, @lines) = ('');
  while (time < $deadline) {
    next unless $sel->can_read(0.2);
    my $n = sysread($fh, my $chunk, 4096);
    last unless $n;
    $buf .= $chunk;
    @lines = split /\n/, $buf;
    last if grep { $_ =~ $until } @lines;
  }
  return @lines;
}

for my $name (sort keys %backend) {
  my $b     = $backend{$name};
  my $pkg   = "TL::$name";
  my $table = "forkedlive_${name}_$$";
  my $parent = $$;

  subtest "live transport: $name" => sub {
    eval defs($pkg, $table, $b->{comp}) or die "defs: $@";

    my $schema = "${pkg}::Schema"->connect(connect_args($b));
    my $dbh    = $schema->storage->dbh;
    $dbh->do("DROP TABLE IF EXISTS $table");
    $dbh->do("CREATE TABLE $table (id integer primary key, val varchar(50))");
    $dbh->do("INSERT INTO $table (id, val) VALUES (1, 'a')");

    is($schema->storage->_async_mode, 'forked', "$name: connection chose the forked mode");

    # ---------------------------------------------------------------------
    # 1. A *_async inside a txn_do_async body, against a real lock.
    #
    # The body changes a row, then update_async's the SAME row. The nested
    # query forks a grandchild with a connection of its own that never saw
    # the BEGIN: it cannot get past the lock the body is holding, and the
    # body is waiting for it. Nothing in the transport can resolve that --
    # what the test claims is that it does not end as a silent success:
    #   PG      the nested UPDATE waits on the row lock: still pending after
    #           the window, the Future never completes. Nor does the body
    #           get out: the grandchild inherited the socket of the body's
    #           connection and the write end of the body's result pipe, so
    #           neither the server (lock) nor the parent (EOF) ever sees the
    #           body end -- a deadlock only the watchdog resolves
    #   SQLite  the nested UPDATE fails with "database is locked"
    # The scenario runs in a process group of its own under a watchdog,
    # because for PG there is no end to wait for.
    # ---------------------------------------------------------------------
    {
      pipe(my $rr, my $rw) or die "pipe: $!";
      my $helper = fork();
      die "fork: $!" unless defined $helper;
      if (!$helper) {
        close $rr;
        POSIX::setsid();
        $SIG{ALRM} = sub { POSIX::_exit(3) };
        alarm 60;
        my $say = sub { my $l = flat(@_) . "\n"; syswrite($rw, $l) };
        my $outer = eval {
          $schema->storage->txn_do_async(sub {
            my $row   = $schema->resultset('Row')->find(1);
            my $other = $schema->resultset('Row')->find(1);
            $row->update({ val => 'in-txn' });             # sync, in this txn
            my $nested = $other->update_async({ val => 'nested' });
            my $until  = time + 2;
            until ($nested->is_ready or time > $until) { select undef, undef, undef, 0.05 }
            if (!$nested->is_ready) {
              $say->('nested pending');
              # no way forward: leave without committing (the transaction
              # rolls back with the connection)
              POSIX::_exit(0);
            }
            if ($nested->is_failed) {
              my $e = (eval { $nested->get; 1 } ? '' : $@);
              $say->('nested failed', $e);
            }
            else { $say->('nested ok') }
            return 'body-done';
          })->get;
        };
        $say->('outer', ($@ ? 'failed' : 'ok'), flat($@ // ''));
        POSIX::_exit(0);
      }
      close $rw;

      my @lines = read_lines($rr, qr/^outer /, $name eq 'pg' ? 10 : 25);
      my $hung  = !grep { /^outer / } @lines;
      kill 'KILL', -$helper;          # the helper's group, grandchildren included
      waitpid($helper, 0);

      if ($name eq 'sqlite') {
        ok(!$hung, 'sqlite: the scenario came to an end by itself, no watchdog needed');
      }
      else {
        ok($hung, 'pg: the scenario does not come to an end by itself -- the watchdog ended it (nothing times out in the transport)');
      }
      my ($nested) = grep { /^nested / } @lines;
      my ($outer)  = grep { /^outer /  } @lines;
      diag("$name nested: " . ($nested // "none") . " / " . ($outer // "no outer line")) if $ENV{TEST_VERBOSE};

      if ($name eq 'sqlite') {
        like($nested // '', qr/^nested failed .*database is locked/i,
          'sqlite: the nested update_async fails with "database is locked"');
        like($outer // '', qr/^outer ok/, 'sqlite: the outer transaction still completes');
        is($dbh->selectrow_array("SELECT val FROM $table WHERE id = 1"), 'in-txn',
          'sqlite: the body\'s own change is committed, the nested one never happened');
      }
      else {
        is($nested // '', 'nested pending',
          'pg: the nested update_async is still pending after 2 s -- it waits on the body\'s row lock');
        unlike($outer // '', qr/^outer ok/,
          'pg: the stuck transaction is never reported as a success');
        isnt($dbh->selectrow_array("SELECT val FROM $table WHERE id = 1"), 'in-txn',
          'pg: ... and its change was rolled back by the kill, not committed');
      }
      unlike($nested // '', qr/^nested ok/,
        "$name: the nested query on a locked row never passes silently");

      $dbh->do('SET lock_timeout = 15000') if $name eq 'pg';   # the dropped grandchild may still hold on
      $dbh->do("UPDATE $table SET val = 'a'");
    }

    # ---------------------------------------------------------------------
    # 2. Real resource shortage, in a subprocess started through `ulimit`.
    #
    # BSD::Resource is not a dependency; bash's `ulimit` lowers the limit
    # before the perl starts. What the process is told is the claim, and it
    # matches the code contract of t/08: a failed fork or pipe is a croak out
    # of the *_async call (there is no child and no pipe a Future could
    # stand for); a child that cannot open its own connection is an ordinary
    # failed Future. Neither leaves a child or a pipe behind, and the backend
    # works again once the system call does.
    # ---------------------------------------------------------------------
  SKIP: {
      my $bash = -x '/bin/bash' ? '/bin/bash' : undef;
      skip 'no /bin/bash for ulimit', 12 unless $bash;

      my $script = <<'EOS';
use strict; use warnings;
use POSIX qw(WNOHANG);
use DBIO::Forked;
eval $ENV{TL_DEFS} or die $@;
my $schema = "$ENV{TL_PKG}::Schema"->connect($ENV{TL_DSN}, $ENV{TL_USER}, $ENV{TL_PASS},
  { async => 'forked', AutoCommit => 1, RaiseError => 1 });
my $mode = $ENV{TL_MODE};
sub say1 { my $m = join ' ', @_; $m =~ s/\s+/ /g; print "$m\n" }
my $row = $schema->resultset('Row')->find(1);
# modules loaded and the pools of the connection warm before the limit bites
$row->update_async({ val => 'warm' })->get unless $mode eq 'nproc';
my @held;
unless ($mode eq 'nproc') {
  while (open(my $fh, '<', '/dev/null')) { push @held, $fh }
  pop @held for 1 .. ($mode eq 'pipe' ? 0 : 2);    # descriptors left for the call
}
my $f = eval { $row->update_async({ val => "x$$" }) };
say1('call', $f ? 'future' : 'croak');
say1('call_err', $@) unless $f;
if ($f) {
  my $ok = eval { local $SIG{ALRM} = sub { die "hung\n" }; alarm 20; $f->get; alarm 0; 1 };
  say1('get', $ok ? 'ok' : 'failed');
  say1('get_err', $@) unless $ok;
  undef $f;
}
say1('reaped', waitpid(-1, WNOHANG));    # -1: no child left, zombie or not
@held = ();
if ($mode eq 'nproc') {
  say1('sync_after', $schema->resultset('Row')->count);
}
else {
  my $ok = eval { $row->update_async({ val => 'recovered' })->get; 1 };
  say1('recovered', $ok ? 1 : 0);
  say1('recovered_err', $@) unless $ok;
}
EOS
      my $run = sub {
        my ($mode, $limit) = @_;
        local $ENV{TL_DEFS} = defs($pkg, $table, $b->{comp});
        local $ENV{TL_PKG}  = $pkg;
        local $ENV{TL_DSN}  = $b->{dsn};
        local $ENV{TL_USER} = $b->{user};
        local $ENV{TL_PASS} = $b->{pass};
        local $ENV{TL_MODE} = $mode;
        local $ENV{PERL5LIB} = join ':', @INC;
        open(my $out, '-|', $bash, '-c', "ulimit $limit; exec \"\$0\" -e \"\$1\"", $^X, $script)
          or die "run: $!";
        my %r;
        my @l = read_lines($out, qr/^(?:recovered|sync_after) /, 60);
        close $out;
        for (@l) { my ($k, $v) = split / /, $_, 2; $r{$k} = $v }
        return \%r;
      };

      # pipe() itself fails: no descriptor left for it
      my $r = $run->(pipe => '-n 80');
      is($r->{call}, 'croak', "$name: no descriptor left for the pipe -- the call croaks");
      like($r->{call_err} // '', qr/pipe failed: Too many open files/,
        "$name: ... naming pipe and the system's reason");
      is($r->{reaped}, -1, "$name: ... and nothing was forked");
      is($r->{recovered}, 1, "$name: ... the backend works again once descriptors are free");

      # the pipe fits, the child's own connection does not
      $r = $run->(child => '-n 80');
      is($r->{call}, 'future', "$name: descriptors for the pipe only -- the call returns a Future");
      if ($name eq 'sqlite') {
        is($r->{get}, 'failed', 'sqlite: ... which fails, the child cannot open the database file');
        like($r->{get_err} // '', qr/unable to open database file/,
          'sqlite: ... with the child\'s own message');
      }
      else {
        # libpq needs one socket, and the child closes the handle it
        # inherited before it opens the new one: two free descriptors are
        # enough for it. Starving it is not deterministic -- what is claimed
        # is that the outcome is a clean one either way
        like($r->{get} // '', qr/^(?:ok|failed)$/,
          'pg: ... which ends, ok or failed, never hangs: ' . ($r->{get} // 'none'));
        like($r->{get_err} // 'x', qr/\S/, 'pg: ... and a failure, if any, carries a message');
      }
      is($r->{reaped}, -1, "$name: ... and the child is reaped, no zombie");
      is($r->{recovered}, 1, "$name: ... the backend works again once descriptors are free");

      # fork() itself fails: RLIMIT_NPROC is below the user's process count
      $r = $run->(nproc => '-u 1');
      is($r->{call}, 'croak', "$name: no process left -- the call croaks");
      like($r->{call_err} // '', qr/fork failed: Resource temporarily unavailable/,
        "$name: ... naming fork and the system's reason");
      is($r->{reaped} . '/' . ($r->{sync_after} // 'none'), '-1/1',
        "$name: ... no child, and the parent's own connection still answers");
    }

    # ---------------------------------------------------------------------
    # 3. A broker that dies when the child asks it again, with a real
    #    handle in the parent. The parent's connection was made through the
    #    broker; only the child's reconnect is refused.
    # ---------------------------------------------------------------------
  SKIP: {
      skip 'the installed DBIO core predates connect options beside an AccessBroker (core k243)', 9
        unless DBIO::Storage::Async->can('_takes_broker_connect_options');

      {
        package TL::Broker;
        our @ISA = ('DBIO::AccessBroker::Static');
        our $PARENT;
        sub connect_info_for_storage {
          my $self = shift;
          die "TL::Broker: the vault is sealed (asked in pid $$)\n" if $$ != $PARENT;
          return $self->next::method(@_);
        }
      }
      local $TL::Broker::PARENT = $parent;

      my $broker = TL::Broker->new(
        dbname   => $b->{dsn},
        username => $b->{user},
        password => $b->{pass},
      );
      my $brokered = "${pkg}::Schema"->connect($broker, { async => 'forked', AutoCommit => 1, RaiseError => 1 });

      is($brokered->resultset('Row')->count, 1, "$name: the parent connects through the broker");
      my $handle = $brokered->storage->_dbh;
      my $row    = $brokered->resultset('Row')->find(1);

      my $f = $row->update_async({ val => 'via-child' });
      my $ok = eval { $f->get; 1 };
      ok(!$ok, "$name: update_async whose child cannot get its connection details fails");
      like($@, qr/TL::Broker: the vault is sealed \(asked in pid (\d+)\)/,
        "$name: ... with the broker's own message");
      my ($asked) = $@ =~ /asked in pid (\d+)/;
      isnt($asked, $parent, "$name: ... asked from the child, not from the parent");
      ok($f->is_failed, "$name: ... a failed Future");

      my $t = eval { $brokered->storage->txn_do_async(sub { 1 })->get };
      like($@, qr/vault is sealed/, "$name: txn_do_async fails the same way, before BEGIN");

      ok($handle->ping && $handle->{Active}, "$name: the parent's DBD handle is intact");
      is($brokered->storage->_dbh, $handle, "$name: ... the very same handle");
      is($brokered->resultset('Row')->count, 1, "$name: ... and still answers queries");
      my $reaped = waitpid(-1, WNOHANG);
      ok($reaped == -1, "$name: no child left behind (waitpid -> $reaped)");
    }

    # ---------------------------------------------------------------------
    # clean up
    # ---------------------------------------------------------------------
    $dbh->do("DROP TABLE IF EXISTS $table");
    my $reaped = waitpid(-1, WNOHANG);
    ok($reaped == -1 || $reaped == 0, "$name: no unreaped children (waitpid -> $reaped)");
  };
}

done_testing;
