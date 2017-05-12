
use strict;
use Test::More;
use FindBin qw($Bin);
use File::Basename;
use File::Path qw(remove_tree);
use File::Spec;
use YAML qw(LoadFile Dump);
use Test::Deep;

plan skip_all => 'No DBD::SQLite installed'
  unless eval { require DBD::SQLite };

my $testdir = File::Spec->rel2abs( File::Spec->catdir( dirname($0), 't' . basename($0) ) );
$testdir =~ s/\.t$//;
die "cannot find testdir '$testdir'" unless -d $testdir;

my $db = "$testdir/delta.db";
$ENV{TEST_DELTA_DB} = "$testdir/delta.db";
unshift @INC, "$testdir/lib";
require_ok( 'TestDelta' );

# Setup
unlink $db if -f $db;
-d "$Bin/applied" and remove_tree("$Bin/applied");

ok(chdir("$testdir/delta"), "chdir to $testdir/delta ok");
my ($count, $delta, $statements, $expected);

# Check deltas to apply
{
  local $SIG{__WARN__} = sub {};
  ($count, $delta) = TestDelta->run('-q');
}
is($count, 2, "found 2 deltas to apply");

# Apply first
($count, $statements) = TestDelta->run('-qs', $delta->[0]);
is($count, 3, "3 statements applied");
$expected = LoadFile('../expected/aa.yml');
cmp_deeply($statements, $expected, 'aa statements');

# Apply second
($count, $statements) = TestDelta->run('-qs', $delta->[1]);
is($count, 6, "6 statements applied");
$expected = LoadFile('../expected/bb.yml');
cmp_deeply($statements, $expected, 'bb statements');
# print Dump $statements;

# Cleanup
unless ($ENV{TEST_DELTA_KEEP_DB}) {
  unlink $db;
  -d "$Bin/applied" and remove_tree("$Bin/applied");
}

done_testing;

