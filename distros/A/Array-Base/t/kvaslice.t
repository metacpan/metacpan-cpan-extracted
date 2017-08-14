use warnings;
use strict;

BEGIN {
	if("$]" < 5.019004) {
		require Test::More;
		Test::More::plan(skip_all =>
			"no array pair slice on this Perl");
	}
}

use Test::More tests => 8;

our @t = qw(a b c d e f);
our $r = \@t;
our @i4 = (3, 5, 3, 5);

use Array::Base +3;

no warnings "syntax";

is_deeply [ scalar %t[3,4] ], [ "b" ];
is_deeply [ %t[3,4,8,9] ], [ 3, "a", 4, "b", 8, "f", 9, undef ];
is_deeply [ scalar %t[@i4] ], [ "c" ];
is_deeply [ %t[@i4] ], [ 3, "a", 5, "c", 3, "a", 5, "c" ];
is_deeply [ scalar %{$r}[3,4] ], [ "b" ];
is_deeply [ %{$r}[3,4,8,9] ], [ 3, "a", 4, "b", 8, "f", 9, undef ];
is_deeply [ scalar %{$r}[@i4] ], [ "c" ];
is_deeply [ %{$r}[@i4] ], [ 3, "a", 5, "c", 3, "a", 5, "c" ];

1;
