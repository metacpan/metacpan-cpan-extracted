use warnings;
use strict;

use Test::More tests => 20;

our @t;
our @i5 = (3, 3, 3, 3, 3);

use Array::Base +3;

@t = qw(a b c d e f);
is_deeply [ scalar splice @t ], [qw(f)];
is_deeply \@t, [];

@t = qw(a b c d e f);
is_deeply [ splice @t ], [qw(a b c d e f)];
is_deeply \@t, [];

@t = qw(a b c d e f);
is_deeply [ scalar splice @t, 5 ], [qw(f)];
is_deeply \@t, [qw(a b)];

@t = qw(a b c d e f);
is_deeply [ splice @t, 5 ], [qw(c d e f)];
is_deeply \@t, [qw(a b)];

@t = qw(a b c d e f);
is_deeply [ scalar splice @t, @i5 ], [qw(f)];
is_deeply \@t, [qw(a b)];

@t = qw(a b c d e f);
is_deeply [ splice @t, @i5 ], [qw(c d e f)];
is_deeply \@t, [qw(a b)];

@t = qw(a b c d e f);
is_deeply [ scalar splice @t, 5, 2 ], [qw(d)];
is_deeply \@t, [qw(a b e f)];

@t = qw(a b c d e f);
is_deeply [ splice @t, 5, 2 ], [qw(c d)];
is_deeply \@t, [qw(a b e f)];

@t = qw(a b c d e f);
is_deeply [ scalar splice @t, 5, 2, qw(x y z) ], [qw(d)];
is_deeply \@t, [qw(a b x y z e f)];

@t = qw(a b c d e f);
is_deeply [ splice @t, 5, 2, qw(x y z) ], [qw(c d)];
is_deeply \@t, [qw(a b x y z e f)];

1;
