use strict;
use warnings;
use Test::More;

# GUARD: a test file of this distribution sets the process alarm once, for
# itself as a whole, and never clears it; a wait that wants a timeout of its
# own gets it from t/lib/GuardedWait.pm (karr k88).
#
# WHY: a process has ONE alarm. Nine live files each carried a private
#
#   local $SIG{ALRM} = sub { die "TIMEOUT awaiting $what\n" };
#   alarm 15;
#   EV::run(EV::RUN_ONCE) until $f->is_ready;
#   alarm 0;
#
# and `alarm 0` clears whatever alarm is running, the file's own backstop
# (`alarm 120;`) with it -- so those files had none, and nothing guarded what
# they did outside such a wait. t/44 set a second alarm around a blocking call
# and started the file's over afterwards. GuardedWait borrows the alarm and
# gives it back (t/79-guarded-wait.t holds that); this file keeps the private
# shape from coming back with the next live test, which is written by copying
# one of the others.
#
# What this file claims, of the code of every t/*.t and t/lib/*.pm (a line
# that is a comment is not code):
#   1. none clears the alarm -- alarm 0, alarm(0), Time::HiRes::alarm(0);
#   2. none sets a handler for it -- $SIG{ALRM}: the file's backstop has
#      none and ends the process, and a wait's timeout is GuardedWait's;
#   3. a file sets the alarm at most once, at file level (`alarm 120;` in the
#      first column); an alarm set anywhere else is listed below with its
#      reason and with the number of calls the reason covers;
#   4. a file that waits through GuardedWait has that file-level alarm: the
#      helper guards its wait and nothing else;
# and of the modules under lib/:
#   5. none sets or clears the alarm or handles it, and the installed test
#      harness waits with core's await, which gives the alarm back (core's
#      k300) -- as does GuardedWait.
#
# A call is looked for as it is written everywhere in this distribution: the
# name, then a number or a variable, with or without a parenthesis.

use File::Glob ();
use FindBin;
use lib "$FindBin::Bin/lib";
use DBIO::Util ();
use DBIO::Test::AsyncHarness ();
use DBIO::PostgreSQL::EV::TestHarness ();
use GuardedWait ();

my $HELPER = 't/lib/GuardedWait.pm';

# file => why the alarm is this file's own subject
my %ITS_SUBJECT = (
  't/79-guarded-wait.t' => 'the test of the helper: it sets an alarm, reads it by taking it off '
    . 'the clock and putting it back, and gives it handlers, to see what the helper leaves of them',
);

# file => [ number of calls, why this is no second alarm of the file ]
my %ELSEWHERE = map {
  $_ => [ 1, q{in a forked child, before the code the child runs: a child does not inherit }
    . q{its parent's alarm and sets one of its own, which the parent's is not touched by} ],
} qw( t/34-pool-fork-guard-mock.t t/35-pool-fork-live.t t/39-listen-seams-live.t );

my $ALARM   = qr/\balarm\b\s*\(?\s*(?=[\d.\$])/;
my $CLEARS  = qr/${ALARM}0+(?:\.0+)?(?![.\d])/;
my $SETS    = qr/${ALARM}(?!0+(?:\.0+)?(?![.\d]))/;
my $HANDLES = qr/\$SIG\s*\{\s*['"]?ALRM['"]?\s*\}/;
my $AT_FILE_LEVEL = qr/^alarm \d+;/;
my $WAITS   = qr/\bGuardedWait\s*->\s*(?:until_ready|run)\b/;

# name => [ [ line number, text ], ... ] without the comment lines
sub code_of {
  my ($root, $prefix, @globs) = @_;
  my %code;
  for my $path (sort map { File::Glob::bsd_glob("$root/$_") } @globs) {
    my $n = 0;
    $code{ $prefix . substr($path, length("$root/")) } = [
      grep { $_->[1] !~ /^\s*#/ }
      map  { [ ++$n, $_ ] }
      split /\n/, DBIO::Util::slurp_file_utf8($path)
    ];
  }
  return \%code;
}

sub lines_with {
  my ($code, $pattern) = @_;
  my %found;
  for my $name (sort keys %$code) {
    my @lines = grep { $_->[1] =~ $pattern } @{ $code->{$name} };
    $found{$name} = \@lines if @lines;
  }
  return \%found;
}

sub shown {
  my ($found, @names) = @_;
  return map { my $name = $_; map { "$name line $_->[0]: $_->[1]\n" } @{ $found->{$name} || [] } } @names;
}

my $t   = code_of($FindBin::Bin, 't/', '*.t', 'lib/*.pm');
my $lib = code_of("$FindBin::Bin/../lib", 'lib/', 'DBIO/PostgreSQL/*.pm', 'DBIO/PostgreSQL/EV/*.pm');

cmp_ok scalar(keys %$t), '>', 80, 'the test files of this distribution were found'
  or BAIL_OUT("no test files under $FindBin::Bin");
ok $t->{$HELPER}, "... $HELPER among them";
ok $lib->{'lib/DBIO/PostgreSQL/EV/TestHarness.pm'}, 'the modules under lib/ were found';

my @unlisted = grep { !$ITS_SUBJECT{$_} } sort keys %$t;

# ---------------------------------------------------------------------------
# 1. Nothing clears the alarm.
# ---------------------------------------------------------------------------

my $clears = lines_with($t, $CLEARS);
my @clearing = grep { $clears->{$_} } @unlisted;
ok !@clearing, 'no test file clears the process alarm -- it is the file\'s own backstop that goes'
  or diag shown($clears, @clearing);

# ---------------------------------------------------------------------------
# 2. Nothing handles it.
# ---------------------------------------------------------------------------

my $handles = lines_with($t, $HANDLES);
my @handling = grep { $handles->{$_} } @unlisted;
ok !@handling, "no test file sets a handler for the alarm -- a wait with a timeout goes through $HELPER"
  or diag shown($handles, @handling);

# ---------------------------------------------------------------------------
# 3. One alarm per file, at file level.
# ---------------------------------------------------------------------------

my $sets = lines_with($t, $SETS);
my (%at_file_level, %elsewhere);
for my $name (keys %$sets) {
  for my $line (@{ $sets->{$name} }) {
    push @{ ($line->[1] =~ $AT_FILE_LEVEL ? \%at_file_level : \%elsewhere)->{$name} }, $line;
  }
}

cmp_ok scalar(grep { $at_file_level{$_} } @unlisted), '>=', 50,
  'the files that guard themselves with an alarm were found';

my @twice = grep { @{ $at_file_level{$_} || [] } > 1 } @unlisted;
ok !@twice, 'no test file sets its file-level alarm twice -- the second starts it over'
  or diag shown(\%at_file_level, @twice);

my @second = grep { $elsewhere{$_} && !$ELSEWHERE{$_} } @unlisted;
ok !@second, "no test file sets an alarm anywhere but at file level -- $HELPER borrows the one there is"
  or diag shown(\%elsewhere, @second);

for my $name (sort keys %ELSEWHERE) {
  my ($count, $why) = @{ $ELSEWHERE{$name} };
  is scalar @{ $elsewhere{$name} || [] }, $count, "$name sets one $count time(s) elsewhere, as listed: $why"
    or diag shown(\%elsewhere, $name);
}

# ---------------------------------------------------------------------------
# 4. A file that waits through the helper guards itself as a whole.
# ---------------------------------------------------------------------------

my $waits = lines_with($t, $WAITS);
my @waiting = grep { $waits->{$_} } @unlisted;
cmp_ok scalar(@waiting), '>=', 10, "the files that wait through $HELPER were found";

my @bare = grep { !$at_file_level{$_} } @waiting;
ok !@bare, 'every one of them sets a file-level alarm for what it does outside those waits'
  or diag map { "$_\n" } @bare;

for my $name (sort keys %ITS_SUBJECT) {
  ok $sets->{$name} || $clears->{$name} || $handles->{$name}, "$name names the alarm, as listed: $ITS_SUBJECT{$name}";
}

# ---------------------------------------------------------------------------
# 5. lib/ has no alarm of its own; both harnesses wait with core's await.
# ---------------------------------------------------------------------------

for my $case ([ 'sets', $SETS ], [ 'clears', $CLEARS ], [ 'handles', $HANDLES ]) {
  my ($does, $pattern) = @$case;
  my $found = lines_with($lib, $pattern);
  ok !%$found, "no module under lib/ $does the process alarm"
    or diag shown($found, sort keys %$found);
}

my $await = DBIO::Test::AsyncHarness->can('await');
ok $await, 'DBIO::Test::AsyncHarness has an await';
is +DBIO::PostgreSQL::EV::TestHarness->can('await'), $await,
  'DBIO::PostgreSQL::EV::TestHarness waits with it, not with one of its own';
is +GuardedWait->can('await'), $await, "... and so does $HELPER";

done_testing;
