use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);

use Data::HashMap::Shared::SS;

# A slide that recovers nothing makes the map wait longer before the next one;
# that wait describes the contents, and clear() replaces them, so it must not
# carry across.

my $dir = tempdir(CLEANUP => 1);
my $m = Data::HashMap::Shared::SS->new("$dir/c.shm", 8192, 0, 0, 0, 65536);

my $i = 0;
$i++ while $m->put(sprintf('k%05d', $i), 'x' x 20);
my $refused = 0;
$refused += !$m->put(sprintf('k%05d', $i++), 'x' x 20) for 1 .. 5000;
is $refused, 5000, 'a full arena refuses, and each slide on it recovers nothing';

$m->clear;

# Refill so that only a slide helps: 32-byte blocks with every other one freed
# leave half the arena in holes no 64-byte block can use.
my $n = 0;
$n++ while $m->put(sprintf('p%05d', $n), 'x' x 20);
$m->remove(sprintf('p%05d', $_)) for grep { $_ % 2 } 0 .. $n - 1;

my $stored = 0;
$stored += $m->put(sprintf('q%05d', $_), 'y' x 40) ? 1 : 0 for 1 .. 500;
cmp_ok $stored, '>', 400, 'after clear() the first refusal compacts at once'
    or diag "only $stored of 500 64-byte stores fitted";

done_testing;
