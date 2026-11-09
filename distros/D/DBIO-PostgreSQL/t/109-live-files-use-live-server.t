use strict;
use warnings;
use Test::More;

# GUARD: a test of this distribution opens no DBI connection of its own
# except through t/lib/LiveServer.pm, and a file that runs against the test
# server asks for that server first (karr k113).
#
# WHY: DBI->connect($dsn, $user, $pass, { RaiseError => 1 }) with the DSN of
# the environment stood in some twenty live files. When it fails, DBI quotes
# the DSN -- and a password in it -- into the test log, and the file dies
# without a plan. The helper reports a failed connect masked and ends the
# file as one failed test (t/108-live-server.t holds that). This file keeps
# the raw connect from coming back with the next live test, which is written
# by copying one of the others.
#
# What this file claims, of the code of every t/*.t and t/lib/*.pm (a line
# that is a comment is not code):
#   1. none calls DBI->connect, DBI->connect_cached or DBI::connect(), except
#      the helper and the files listed below, each with its reason and with
#      the number of calls the reason covers;
#   2. every file that reads the test login from the environment calls
#      LiveServer->require_server -- so a server that is not there fails the
#      file with a plan, whatever the file connects with afterwards.
#
# A call is looked for as it is written everywhere in this distribution, the
# parenthesis directly behind the name. A substitution -- *DBI::connect =
# sub { ... } -- is no call, and neither is the name in a test description.

use File::Basename ();
use File::Glob ();
use FindBin;
use DBIO::Util ();

my $HELPER = 't/lib/LiveServer.pm';

# file => [ number of calls, why this is no connection of a live test ]
my %RAW_CONNECT = (
  't/105-future-io-error-text.t' => [ 1,
    q{connects to dbi:ExampleP:, the driver DBI ships for its own tests: no }
    . q{server, no login, and the DBI error of a plain handle is what the file compares with} ],
  't/106-connect-params-dsn.t' => [ 1,
    q{asks the real DBD::Pg and libpq how they read a DSN the file writes }
    . q{itself, on a socket directory that does not exist: the login is made up, }
    . q{RaiseError and PrintError are off, and only $DBI::errstr is read, which has no DSN in it} ],
);

# file => why it names the variables without being a live file
my %NAMES_THE_LOGIN = (
  $HELPER => 'the helper: the one place that reads them',
  't/108-live-server.t' => 'the offline test of the helper: it sets them, for a server that does not exist',
  't/109-live-files-use-live-server.t' => 'this file: it names them to look for them',
);

my $RAW_CONNECT = qr/\bDBI\s*(?:->|::)\s*connect(?:_cached)?\(/;
my $LOGIN       = qr/DBIO_TEST_PG_/;
my $GATE        = qr/\bLiveServer\s*->\s*require_server\b/;

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

cmp_ok scalar(keys %code), '>', 100, 'the test files of this distribution were found'
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
# 2. A file that reads the test login asks for the server first.
# ---------------------------------------------------------------------------

my @live = grep { my $name = $_; !$NAMES_THE_LOGIN{$name} && grep { $_->[1] =~ $LOGIN } @{ $code{$name} } }
  sort keys %code;

cmp_ok scalar(@live), '>=', 37, 'the live files were found by the login they read';

my @ungated = grep { my $name = $_; !grep { $_->[1] =~ $GATE } @{ $code{$name} } } @live;
ok !@ungated, 'every file that reads DBIO_TEST_PG_* calls LiveServer->require_server'
  or diag map { "$_\n" } @ungated;

for my $name (sort keys %NAMES_THE_LOGIN) {
  ok +(grep { $_->[1] =~ $LOGIN } @{ $code{$name} || [] }),
    "$name names the login, as listed: $NAMES_THE_LOGIN{$name}";
}

done_testing;
