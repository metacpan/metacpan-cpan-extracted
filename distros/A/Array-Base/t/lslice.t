use warnings;
use strict;

use Test::More tests => 8;

our @i4 = (3, 5, 3, 5);

use Array::Base +3;

is_deeply [ scalar qw(a b c d e f)[3,4] ], [ qw(b) ];
is_deeply [ qw(a b c d e f)[3,4,8,9] ], [ qw(a b f), undef ];
is_deeply [ scalar qw(a b c d e f)[@i4] ], [ qw(c) ];
is_deeply [ qw(a b c d e f)[@i4] ], [ qw(a c a c) ];

SKIP: {
	skip "no lexical \$_ on this perl", 4
		if "$]" < 5.009001 || "$]" >= 5.023004;
	eval q{
		no warnings "$]" >= 5.017009 ? "experimental" :
						"deprecated";
		my $_;
		is_deeply [ scalar qw(a b c d e f)[3,4] ], [ qw(b) ];
		is_deeply [ qw(a b c d e f)[3,4,8,9] ], [ qw(a b f), undef ];
		is_deeply [ scalar qw(a b c d e f)[@i4] ], [ qw(c) ];
		is_deeply [ qw(a b c d e f)[@i4] ], [ qw(a c a c) ];
	};
}

1;
