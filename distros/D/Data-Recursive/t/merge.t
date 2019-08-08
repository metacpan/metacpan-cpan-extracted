use 5.012;
use warnings;
use Data::Recursive qw/merge :const/;
use Test::More;
use Test::Deep;

# merge merges hashrefs
my $ret;
my $aa = {a => 1, b => 2, c => 3, d => 4};
my $bb = {c => 'c', d => 'd', e => 'e', f => 'f'};
$ret = merge($aa, $bb); 
cmp_deeply($aa, {a => 1, b => 2, c => 'c', d => 'd', e => 'e', f => 'f'});
is($ret, $aa); # check that the same hashref is returned

# merge merges arrayrefs
$aa = [1,2,3];
$bb = [3,2,1];
$ret = merge($aa, $bb);
is($ret, $aa);
cmp_deeply($aa, [3,2,1]);
shift @$aa;
cmp_deeply($bb, [2,1]);

$aa = [1,2,3];
$bb = [3,2,1];
$ret = merge($aa, $bb, ARRAY_CONCAT);
is($ret, $aa);
cmp_deeply($aa, [1,2,3,3,2,1]);
shift @$aa;
cmp_deeply($bb, [3,2,1]);

$aa = [1,2,3];
$bb = [3,2,1];
$ret = merge($aa, $bb, ARRAY_MERGE);
is($ret, $aa);
cmp_deeply($aa, [3,2,1]);
shift @$aa;
cmp_deeply($bb, [3,2,1]);

$aa = [1,2,3];
$bb = [3,2,1];
$ret = merge($aa, $bb, ARRAY_MERGE|COPY_DEST);
ok($ret ne $aa);
cmp_deeply($aa, [1,2,3]);
cmp_deeply($ret, [3,2,1]);
shift @$ret;
cmp_deeply($bb, [3,2,1]);

# merge merges scalars
$aa = 10;
$bb = 20;
$ret = merge($aa, $bb);
is($ret, $aa);
is($aa, 20);
$aa++;
is($bb, 20); # no aliases possible on top-level

$aa = 20;
$ret = merge($aa, undef);
is($aa, undef);

$aa = 20;
$ret = merge($aa, 30, LAZY);
is($aa, 20);

done_testing();
