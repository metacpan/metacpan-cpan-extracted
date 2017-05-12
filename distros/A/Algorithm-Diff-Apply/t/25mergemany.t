#!/usr/bin/perl -w
# Big test case where the diffs don't overlap.

use Algorithm::Diff  qw{diff};
use Test::Simple tests => 1;
use Algorithm::Diff::Apply qw{apply_diffs};

$orig =             [qw{a b c d e f       g h i j k l m n o p q       r s t u}] ;
$dif1 = diff($orig, [qw{a   c d e f       g h i j k l m n o p q       r s t u}] );
$dif2 = diff($orig, [qw{a b c d e f       g h i j k l m n o p q       r      }] );
$dif3 = diff($orig, [qw{a b c d     z y x g h i j k l m n o p q       r s t u}] );
$dif4 = diff($orig, [qw{a b c d e f       g j i h   l m n o p q       r s t u}] );
$dif5 = diff($orig, [qw{a b c d e f       g h i j k l   n o p q       r s t u}] );
$dif6 = diff($orig, [qw{a b c d e f       g h i j k l m n     q fnord r s t u}] );

$expc = join(':',    qw{a   c d     z y x g j i h   l   n     q fnord r      });
$resu = join(':', apply_diffs($orig,
			      d1 => $dif1,
			      d2 => $dif2,
			      d3 => $dif3,
			      d4 => $dif4,
			      d5 => $dif5,
			      d6 => $dif6,
			      ) );
ok($resu eq $expc)
	or print STDERR "\n   GOT: $resu\nWANTED: $expc\n\n";
