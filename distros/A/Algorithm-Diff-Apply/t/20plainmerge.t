#!/usr/bin/perl -w
# Simple test case where the diffs don't overlap.

use Algorithm::Diff qw{diff};
use Test::Simple tests => 1;
use Algorithm::Diff::Apply qw{apply_diffs};

$orig =             [qw{a b c d   e f g h i j   k         l m n o}] ;
$dif1 = diff($orig, [qw{a b x y z e f g h i j A k         l   n o}] );
$dif2 = diff($orig, [qw{a b c d   e     h i j   k B C D E l m n  }] );
$expc = join(':',    qw{a b x y z e     h i j A k B C D E l   n  }  );
$resu = join(':', apply_diffs($orig, d1=>$dif1, d2=>$dif2) );
ok($resu eq $expc)
	or print STDERR "\n   GOT: $resu\nWANTED: $expc\n\n";

