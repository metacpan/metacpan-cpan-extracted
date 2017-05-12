
use Test::More 'no_plan';
use Test::NoWarnings;

use_ok('Array::Compare');

my $comp = Array::Compare->new;

my @A = qw/0 1 2 3 4 5 6 7 8/;
my @B = qw/0 1 2 3 4 5 X 7 8/;
my @C = @A;

my %skip1 = (6 => 1);
my %skip2 = (5 => 1);
my %skip3 = (6 => 0);

# Compare two different arrays - should fail
ok(not $comp->compare(\@A, \@B));

# Compare two different arrays but ignore differing column - should succeed
$comp->Skip(\%skip1);
ok($comp->compare(\@A, \@B));

# compare two different arrays but ignore non-differing column - should fail
$comp->Skip(\%skip2);
ok(not $comp->compare(\@A, \@B));

# Compare two different arrays but ignore differing column (badly) 
# - should fail as skip value is 0
$comp->Skip(\%skip3);
ok(not $comp->compare(\@A, \@B));

# Change separator and compare two identical arrays - should succeed
$comp->Sep('|');
ok($comp->compare(\@A, \@C));

# These tests should generate fatal errors - hence the evals

# Compare a number with an array
eval { print $comp->compare(1, \@A) };
ok($@);

# Compare an array with a number
eval { print $comp->compare(\@A, 1) };
ok($@);

# Call compare with only one argument
eval { print $comp->compare(\@A) };
ok($@);

# Switch to full comparison
$comp->DefFull(1);
ok($comp->DefFull);
$comp->Skip({});

# @A and @B differ in column 6
# Array context
my @diffs = $comp->compare(\@A, \@B);
ok(scalar @diffs == 1 && $diffs[0] == 6);

# Scalar context
my $diffs =  $comp->compare(\@A, \@B);
ok($diffs);

# @A and @B differ in column 6 (which we ignore)
$comp->Skip(\%skip1);
# Array context
@diffs = $comp->compare(\@A, \@B);
ok(not @diffs);

# Scalar context
$diffs = $comp->compare(\@A, \@B);
ok(not $diffs);

# @A and @C are the same
# Array context
@diffs = $comp->compare(\@A, \@C);
ok(not @diffs);

# Scalar context
$diffs = $comp->compare(\@A, \@C);
ok(not $diffs);

# Test arrays of differing length
my @D = (0 .. 5);
my @E = (0 .. 10);

$comp->DefFull(0);
ok( not $comp->compare(\@D, \@E));

$comp->DefFull(1);
@diffs = $comp->compare(\@D, \@E);
ok(@diffs == 5);

@diffs = $comp->compare(\@E, \@D);
ok(@diffs == 5);

$diffs = $comp->compare(\@D, \@E);
ok($diffs == 5);

# Test Perms
my @F = (1 .. 5);
my @G = qw(5 4 3 2 1);
my @H = qw(3 4 1 2 5);
my @I = qw(4 3 6 5 2);

ok($comp->perm(\@F, \@G));
ok($comp->perm(\@F, \@H));
ok(not $comp->perm(\@F, \@I));

my @J = ('array with', 'white space');
my @K = ('array  with', 'white	space');
ok($comp->compare(\@J, \@K));

# Turn off whitespace
$comp->WhiteSpace(0);
ok(not $comp->compare(\@J, \@K));

$comp->DefFull(0);
ok($comp->compare(\@J, \@K));

# Turn on whitespace
$comp->WhiteSpace(1);
ok(not $comp->compare(\@J, \@K));

my @L = qw(ArRay WiTh DiFfErEnT cAsEs);
my @M = qw(aRrAY wItH dIfFeReNt CaSeS);
ok(not $comp->compare(\@L, \@M));

# Turn of case sensitivity
$comp->Case(0);
ok($comp->compare(\@L, \@M));

$comp->DefFull(1);
ok(not $comp->compare(\@L, \@M));

my @N = (undef, 1 .. 3);
my @O = (undef, 1 .. 3);

$comp->DefFull(0);
ok($comp->compare(\@N, \@O));

$comp->DefFull(1);
ok(not $comp->compare(\@N, \@O));
