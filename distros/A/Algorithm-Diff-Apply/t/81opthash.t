#!/usr/bin/perl -w
# Ensure that key-based hashing works.

use Algorithm::Diff qw{diff};
use Test::Simple tests => 2;
use Algorithm::Diff::Apply qw{apply_diffs};
use strict;

my ($original, $derived1, $derived2, $changes1, $changes2, $result, $hasher);

# First consider double-underscore-prefixed numbers to all be
# identical. We shouldn't get a conflict.

sub mkhash
{
	local $_ = shift;
	/^__\d+$/ and return "__";
	return $_;
}

$original = [qw{a b c d e f g     h i j k l m n o   x   y}] ;
$derived1 = [qw{a b c d     x y z h i j k l m n o __1 __4}] ;
$derived2 = [qw{a b c d     x y z h i j k l m n o __3 __7}] ;
$changes1 = diff($original, $derived1);
$changes2 = diff($original, $derived2);

$result = join(':', apply_diffs($original, { key_generator => \&mkhash },
				d1 => $changes1,
				d2 => $changes2,
				));
ok($result !~ /\>\>\>/);

# Then make sure we're not deluding ourselves by detecting a genuine
# conflict when called with an otherwise identical context.

$original = [qw{a b c d e f g        h i j k l m n o   x   y}] ;
$derived1 = [qw{a b c d     x  y  z  h i j k l m n o __1 __4}] ;
$derived2 = [qw{a b c d     z! y! x! h i j k l m n o __3 __7}] ;
$changes1 = diff($original, $derived1);
$changes2 = diff($original, $derived2);

$result = join(':', apply_diffs($original, { key_generator => \&mkhash },
				d1 => $changes1,
				d2 => $changes2,
				));
ok($result =~ /\>\>\>/);
