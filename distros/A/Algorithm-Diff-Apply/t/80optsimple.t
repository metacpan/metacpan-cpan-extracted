#!/usr/bin/perl -w
# Tests of simple, identical-chunk optimisation.

use Algorithm::Diff qw{diff};
use Test::Simple tests => 9;
use Algorithm::Diff::Apply qw{apply_diffs optimise_remove_duplicates};
use constant TEST_OPTIMISERS => [\&optimise_remove_duplicates];
use strict;

my ($original, $derived, $changes, $expected, $result);

$original = [qw{a b c d e f g     h i j k l m n o p q}] ;
$derived  = [qw{a b c d     x y z h i j k l m n o p q}] ;
$changes  = diff($original, $derived);

# First of all, we should get a conflict if we override the
# optimisation completely.

$expected = join(':', @$derived);
$result   = join(':', apply_diffs($original, {optimisers => []},
				  d1 => $changes,
				  d2 => $changes,
				  ));
ok($result =~ /\>\>\>/);

# Allowing normal behaviour makes the problem above go away ...

$result   = join(':', apply_diffs($original, {optimisers => TEST_OPTIMISERS},
				  d1 => $changes,
				  d2 => $changes,
				  ));
ok($result !~ /\>\>\>/);
ok($result eq $expected);

# ... no matter how many identical chunks we throw at it.

$result   = join(':', apply_diffs($original, {optimisers => TEST_OPTIMISERS},
				  d1 => $changes,
				  d2 => $changes,
				  d3 => $changes,
				  d4 => $changes,
				  d5 => $changes,
				  ));
ok($result !~ /\>\>\>/);
ok($result eq $expected);

# The blocks remaining after this optimisation can still conflict with
# other diffs - and when optimise_remove_duplicates() optimises a
# bunch of identical hunks from different tagged sequences, the
# remaining hunk is kept under the first tag.

my $derived2 = [qw{a b c d e f 1 2 3 h i j k l m n o p q}];
my $changes2 = diff($original, $derived2);
$result   = join(':', apply_diffs($original, {optimisers => TEST_OPTIMISERS},
				  '_03_third' => $changes2,
				  '_02_second' => $changes,  # }__ identical
				  '_01_first' => $changes,   # }
				  ));
ok($result =~ />>>/);
ok($result =~ />>>\s+_01_first/);
ok($result !~ />>>\s+_02_second/);
ok($result =~ />>>\s+_03_third/);

