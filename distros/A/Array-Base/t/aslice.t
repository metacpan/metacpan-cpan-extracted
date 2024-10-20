use warnings;
use strict;

use Test::More tests => 16;

our @t = qw(a b c d e f);
our $r = \@t;
our @i4 = (3, 5, 3, 5);

use Array::Base +3;

is_deeply [ scalar @t[3,4] ], [ qw(b) ];
is_deeply [ @t[3,4,8,9] ], [ qw(a b f), undef ];
is_deeply [ scalar @t[@i4] ], [ qw(c) ];
is_deeply [ @t[@i4] ], [ qw(a c a c) ];
is_deeply [ scalar @{$r}[3,4] ], [ qw(b) ];
is_deeply [ @{$r}[3,4,8,9] ], [ qw(a b f), undef ];
is_deeply [ scalar @{$r}[@i4] ], [ qw(c) ];
is_deeply [ @{$r}[@i4] ], [ qw(a c a c) ];

SKIP: {
	skip "no lexical \$_ on this perl", 8
		if "$]" < 5.009001 || "$]" >= 5.023004;
	eval q{
		no warnings "$]" >= 5.017009 ? "experimental" :
						"deprecated";
		my $_;
		is_deeply [ scalar @t[3,4] ], [ qw(b) ];
		is_deeply [ @t[3,4,8,9] ], [ qw(a b f), undef ];
		is_deeply [ scalar @t[@i4] ], [ qw(c) ];
		is_deeply [ @t[@i4] ], [ qw(a c a c) ];
		is_deeply [ scalar @{$r}[3,4] ], [ qw(b) ];
		is_deeply [ @{$r}[3,4,8,9] ], [ qw(a b f), undef ];
		is_deeply [ scalar @{$r}[@i4] ], [ qw(c) ];
		is_deeply [ @{$r}[@i4] ], [ qw(a c a c) ];
	};
}

1;
