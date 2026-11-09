use strict;
use warnings;
use Test::More;

# GUARD, karr k88 (as t/109-live-files-use-live-server.t of dbio-postgresql,
# karr k113 there): a test of this distribution opens no DBI connection of its
# own except through t/lib/LiveServer.pm, and a file that runs against the test
# server asks for that server first.
#
# WHY: a raw DBI->connect($dsn, ...) that fails has DBI quote the DSN -- and a
# password in it -- into the test log, and the file dies without a plan. The
# helper ends the file as one failed test with the reason masked (t/86, t/87).
# This file keeps the raw connect, and a live file with no gate, from coming
# back with the next live test, which is written by copying one of the others.
#
# What this file claims, of the code of every t/*.t and t/lib/*.pm (a comment
# line is not code):
#   1. none calls DBI->connect, DBI->connect_cached or DBI::connect(), except
#      the helper and the files listed below, each with its reason and the
#      number of calls the reason covers;
#   2. every file that reads the test login (DBIO_TEST_PG_*) or declares itself
#      live (skip_all_unless_live) calls LiveServer->require_server or
#      LiveServer->control_dbh -- the second asks the server for a connection
#      just as the first does, and is what a file with a connection of its own
#      calls -- so a server that is not there fails the file with a plan.
#
# Not the same as dbio-postgresql's guard in one respect: there the gate is
# require_server alone. Here control_dbh counts, because a file that needs an
# observer connection has no use for a second one only to ask.
#
# A call is looked for as it is written everywhere in this distribution, the
# parenthesis directly behind the name. A substitution -- *DBI::connect =
# sub { ... } -- is no call, and neither is the name in a test description.

use File::Glob ();
use FindBin;
use DBIO::Util ();

my $HELPER = 't/lib/LiveServer.pm';

# file => [ number of calls, why this is no connection of a live test ]
my %RAW_CONNECT = (
  't/11-access-broker-live.t' => [ 1,
    q{logs in as a role the file created itself, which the helper's login is not; the call is the probe, inside an eval, and a refusal is reported} ],
  't/53-dbi-to-conninfo.t' => [ 1,
    q{asks the real DBI what it hands DBD::Pg, with a driver that is made up and no server: nothing to log in to} ],
);

# file => why it names the login without being a live file
my %NAMES_THE_LOGIN = (
  $HELPER => 'the helper: the one place that reads them',
  't/86-live-server-failed-connect.t' => 'offline: it sets them, for a server that does not exist',
  't/87-live-server.t' => 'offline: it sets them, for a server that does not exist',
  't/88-live-files-use-live-server.t' => 'this file: it names them to look for them',
);

my $RAW_CONNECT = qr/\bDBI\s*(?:->|::)\s*connect(?:_cached)?\(/;
my $LIVE        = qr/DBIO_TEST_PG_|\bskip_all_unless_live\b/;
my $GATE        = qr/\bLiveServer\s*->\s*(?:require_server|control_dbh)\b/;

my $t = $FindBin::Bin;
my %code;   # file => [ [ line number, text ], ... ] without the comment lines
for my $path (sort map { File::Glob::bsd_glob($_) } "$t/*.t", "$t/lib/*.pm") {
  my $name = 't/' . substr($path, length("$t/"));
  my $n = 0;
  $code{$name} = [
    grep { $_->[1] !~ /^\s*#/ }
    map  { [ ++$n, $_ ] }
    split /\n/, DBIO::Util::slurp_file_utf8($path)
  ];
}

cmp_ok scalar(keys %code), '>', 80, 'the test files of this distribution were found'
  or BAIL_OUT("no test files under $t");
ok $code{$HELPER}, "... $HELPER among them";

# ---------------------------------------------------------------------------
# 1. No DBI->connect outside the helper.
# ---------------------------------------------------------------------------

my %raw;
for my $name (sort keys %code) {
  my @lines = grep { $_->[1] =~ $RAW_CONNECT } @{ $code{$name} };
  $raw{$name} = \@lines if @lines;
}

ok $raw{$HELPER}, "$HELPER is where DBI->connect is called";

my @unlisted = grep { $_ ne $HELPER && !$RAW_CONNECT{$_} } sort keys %raw;
ok !@unlisted, "no other test file calls DBI->connect itself -- a live test gets its connection from $HELPER"
  or diag map { my $name = $_; map { "$name line $_->[0]: $_->[1]\n" } @{ $raw{$name} } } @unlisted;

for my $name (sort keys %RAW_CONNECT) {
  my ($count, $why) = @{ $RAW_CONNECT{$name} };
  is scalar @{ $raw{$name} || [] }, $count,
    "$name calls it $count time(s), as listed: $why"
    or diag map { "$name line $_->[0]: $_->[1]\n" } @{ $raw{$name} || [] };
}

# ---------------------------------------------------------------------------
# 2. A file that is live asks for the server first.
# ---------------------------------------------------------------------------

my @live = grep { my $name = $_; !$NAMES_THE_LOGIN{$name} && grep { $_->[1] =~ $LIVE } @{ $code{$name} } }
  sort keys %code;

cmp_ok scalar(@live), '>=', 28, 'the live files were found by the login they read or the skip they call';

my @ungated = grep { my $name = $_; !grep { $_->[1] =~ $GATE } @{ $code{$name} } } @live;
ok !@ungated, 'every live file calls LiveServer->require_server or ->control_dbh'
  or diag map { "$_\n" } @ungated;

for my $name (sort keys %NAMES_THE_LOGIN) {
  ok +(grep { $_->[1] =~ $LIVE } @{ $code{$name} || [] }),
    "$name names the login, as listed: $NAMES_THE_LOGIN{$name}";
}

done_testing;
