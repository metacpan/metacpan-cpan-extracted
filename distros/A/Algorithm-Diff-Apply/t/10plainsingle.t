#!/usr/bin/perl -w
# Test the simple apply_diff function

use Algorithm::Diff qw{diff};
use Test::Simple tests => 5;
use Algorithm::Diff::Apply qw{apply_diff};

# Replacement
$orig =             [qw{a b c d e f g h i j k l    }];
$diff = diff($orig, [qw{a b c d e f g h         z y}]);
$expc = join(':',    qw{a b c d e f g h         z y} );
$resu = join(':', apply_diff($orig, $diff) );
ok($resu eq $expc)
	or print STDERR "\n   GOT: $resu\nWANTED: $expc\n\n";

# Reversal
$orig =             [qw{a b c d e f g h i j k l}];
$diff = diff($orig, [qw{l k j i h g f e d c b a}]);
$expc = join(':',    qw{l k j i h g f e d c b a} );
$resu = join(':', apply_diff($orig, $diff) );
ok($resu eq $expc)
	or print STDERR "\n   GOT: $resu\nWANTED: $expc\n\n";

# Early big removals don't screw things up later on
$orig =             [qw{a b c d e f g h i j k l}];
$diff = diff($orig, [qw{g h 1 2 3 4 k l}]);
$expc = join(':',    qw{g h 1 2 3 4 k l} );
$resu = join(':', apply_diff($orig, $diff) );
ok($resu eq $expc)
	or print STDERR "\n   GOT: $resu\nWANTED: $expc\n\n";

# Hmm
$orig =             [qw{a b c d e f g h}];
$diff = diff($orig, [qw{a b c d e f x y z 1 2 g h}]);
$expc = join(':',    qw{a b c d e f x y z 1 2 g h} );
$resu = join(':', apply_diff($orig, $diff) );
ok($resu eq $expc)
	or print STDERR "\n   GOT: $resu\nWANTED: $expc\n\n";

# Mixed-bag case that's proved problematic before
$orig =             [qw{a b c d e f g h i j k :::}];
$diff = diff($orig, [qw{a x y z f g h 12 34 56 78 910 11 12 13 :::}]);
$expc = join(':',    qw{a x y z f g h 12 34 56 78 910 11 12 13 :::} );
$resu = join(':', apply_diff($orig, $diff) );
ok($resu eq $expc)
	or print STDERR "\n   GOT: $resu\nWANTED: $expc\n\n";

