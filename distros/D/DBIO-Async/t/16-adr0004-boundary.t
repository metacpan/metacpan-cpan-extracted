use strict;
use warnings;
use Test::More;
use File::Temp ();

# OFFLINE tripwire for the ADR 0004 hard boundary (karr k15 point 8): this dist
# ships NO DB-specific code, and needs no concrete DBD. "The skeleton must load
# and work without any concrete DBD installed (only Future / Future::IO + core
# DBIO)" is the sentence in CLAUDE.md; this file is that sentence as a test, so
# that driver glue added here in passing is caught by the suite instead of by a
# user whose sync-only driver suddenly wants DBD::Pg.
#
# WHY A CHILD PROCESS. The obvious in-process form -- load everything, then
# assert !exists $INC{'DBI.pm'} -- does not work here, and the reason is worth
# recording. Core's DBIO::Optional::Dependencies decides at file scope whether
# to list DBD::MariaDB or DBD::mysql in its requirement table, and asks by
# doing `eval { require DBD::MariaDB; 1 }`. On any machine where DBD::MariaDB
# is installed, that one probe loads DBD::MariaDB and through it DBI into every
# process that loads DBIO::Base -- so DBI is in %INC before this dist's first
# line runs, and the assertion is about core, not about us. Weakening it to a
# %INC DELTA does not help either: with DBI already loaded by core, a `use DBI`
# added to this dist adds no new %INC key and the delta stays green. A test
# that cannot go red when the promise breaks is not a test (house rule 7).
#
# So the boundary is asserted the way it is actually meant: in a child perl
# where DBI and every DBD are UNAVAILABLE -- an @INC hook refuses them, exactly
# as a machine without them installed would. Core's probe fails harmlessly
# inside its own eval; this dist has to load, and work, regardless. That form
# is absolute, true on every machine, and a single `use DBI` in lib/ turns it
# red immediately.

my $child = File::Temp->new(SUFFIX => '.pl');
print {$child} <<'CHILD';
use strict;
use warnings;

# A machine with no DBI and no DBD at all, simulated exactly where it matters.
BEGIN {
  unshift @INC, sub {
    my (undef, $file) = @_;
    die "ADR 0004 boundary: $file is not available in this process\n"
      if $file eq 'DBI.pm' or $file =~ m{^DBD/};
    return undef;
  };
}

use DBIO::Async;
use DBIO::Async::Storage;
use DBIO::Async::Pool;
use DBIO::Async::TransactionContext;
use Future;

# Not only loadable -- usable. A lazy `require DBD::Whatever` on the query path
# would survive a load-only check and still couple this dist to a DBD, so the
# transport is actually driven: pool, Future::IO watcher seam, collect.
{
  package NoDbdMock;
  use base 'DBIO::Async::Storage';
  use Future;

  sub _transform_sql            { $_[1] }
  sub _normalize_conninfo       { $_[1] }
  sub _shutdown_pool_connection { close $_[1]{r}; close $_[1]{w} }
  sub _conn_ready               { 1 }
  sub _conn_fileno              { fileno $_[1]{r} }

  sub _create_pool_connection {
    pipe(my $r, my $w) or die "pipe: $!";
    $w->autoflush(1);
    return { r => $r, w => $w };
  }

  sub _submit_query { syswrite $_[1]{w}, 'R'; return }

  sub _collect_result {
    my ($self, $conn) = @_;
    sysread $conn->{r}, my $b, 1;
    return Future->done(['ok']);
  }
}

my $storage = NoDbdMock->new(undef);
$storage->connect_info([{ host => 'localhost' }]);
my $rows = $storage->_query_async('SELECT 1', [])->get;
die "query did not resolve\n" unless ref $rows eq 'ARRAY' && $rows->[0] eq 'ok';
$storage->pool->shutdown;

my @db_specific = grep {
  m{^DBI\.pm$}
    || m{^DBD/}
    || m{^DBIO/(?:PostgreSQL|MySQL|SQLite|Oracle|DB2|Sybase|MSSQL|Firebird|Informix|InterBase|ODBC)\b}
} keys %INC;

print @db_specific ? 'LOADED: ' . join(' ', sort @db_specific) . "\n" : "CLEAN\n";
CHILD
$child->flush;

my @inc = map { "-I$_" } grep { !ref } @INC;
my $out = `$^X @inc $child 2>&1`;
my $rc  = $?;

is $rc, 0,
  'the whole dist loads AND runs a query in a process where DBI and every DBD '
  . 'are unavailable (ADR 0004: only Future / Future::IO + core DBIO)'
  or diag "child output:\n$out";

is $out, "CLEAN\n",
  'and it left no DBI, no DBD and no driver distribution in %INC'
  or diag "child output:\n$out";

# ---------------------------------------------------------------------------
# The other half of the same boundary, cheap enough to ask in-process: this
# dist names no driver distribution. Core's DBD probe cannot mask this one --
# nothing in core loads a DBIO driver dist -- so it is asserted here directly.
# ---------------------------------------------------------------------------

use DBIO::Async;
use DBIO::Async::Storage;
use DBIO::Async::Pool;
use DBIO::Async::TransactionContext;

my @driver_dists = grep {
  m{^DBIO/(?:PostgreSQL|MySQL|SQLite|Oracle|DB2|Sybase|MSSQL|Firebird|Informix)\b}
} keys %INC;

is_deeply [ sort @driver_dists ], [],
  'no DBIO driver distribution is loaded by this dist -- it ships no '
  . 'DB-specific code and names none (ADR 0004 hard boundary)';

done_testing;
