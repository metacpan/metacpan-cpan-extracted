use strict;
use warnings;
use Test::More tests => 34;
use Data::Miscellany qw/
  set_push
  flatten
  flex_grep
  /;

# ======================================================================
# test set_push()
my @f = ({ a => 1, b => 2 }, { a => 1, b => 3, c => 1 },);
set_push @f, { a => 1, b => 4 };
set_push @f, { a => 1, b => 4 }, { a => 1, b => 4 };
set_push @f, { d => 1, b => 4 }, { d => 2, b => 3 };
is_deeply(
    \@f,
    [   { a => 1, b => 2 },
        { a => 1, b => 3, c => 1 },
        { a => 1, b => 4 },
        { d => 1, b => 4 },
        { d => 2, b => 3 },
    ],
    'set_push'
);
@f = (1, 2, 3, 4);
set_push @f, 3, 1, 5, 1, 6;
is_deeply(\@f, [ 1 .. 6 ], 'set_push 2');

# ======================================================================
# test flatten()
is_deeply([ flatten(undef) ], [],   'flatten undef');
is_deeply([ flatten(42) ],    [42], 'flatten scalar');
is_deeply([ flatten(42) ],    [42], 'flatten scalar');
is_deeply([ flatten(42, 23) ], [ (42, 23) ], 'flatten array');
is_deeply([ flatten(42, [23]) ], [ (42, [23]) ], 'flatten complex array');
is_deeply([ flatten([ 23, 42, 123 ]) ], [ 23, 42, 123 ], 'flatten array ref');
is_deeply(
    [ flatten([ 23, [42], 123 ]) ],
    [ 23, [42], 123 ],
    'flatten complex array ref'
);

# ======================================================================
# test flex_grep()
ok(flex_grep('foo',  [qw/foo bar baz/]),     'flex grep 1');
ok(!flex_grep('foo', [qw/bar baz flurble/]), 'flex grep 2');
ok(flex_grep('foo', 1 .. 4, 'flurble', [qw/foo bar baz/]), 'flex grep 3');
ok(!flex_grep('foo', 1 .. 4, [ ['foo'] ], [qw/bar baz/]), 'flex grep 4');

# ======================================================================
# test is_deeply()
my ($a1, $a2, $a3);
$a1 = \$a2;
$a2 = \$a3;
$a3 = 42;
my ($b1, $b2, $b3);
$b1 = \$b2;
$b2 = \$b3;
$b3 = 23;
my $foo = {
    this => [ 1 .. 10 ],
    that => { up => "down", left => "right" },
};
my $bar = {
    this => [ 1 .. 10 ],
    that => { up => "down", left => "right", foo => 42 },
};

# so as to not confuse it with Test::More->is_deeply()
*_is_deeply = *Data::Miscellany::is_deeply;
ok(!_is_deeply('foo', 'bar'), 'is_deeply(): different plain strings');
ok(!_is_deeply({}, []), 'is_deeply(): different types');
ok( !_is_deeply({ this => 42 }, { this => 43 }),
    'is_deeply(): hashes with different values'
);
ok( !_is_deeply({ that => 42 }, { this => 42 }),
    'is_deeply(): hashes with different keys'
);
ok( !_is_deeply([ 1 .. 9 ], [ 1 .. 10 ]),
    'is_deeply(): arrays of different length'
);
ok(!_is_deeply([ undef, undef ], [undef]), 'is_deeply(): arrays of undefs');
ok(!_is_deeply({ foo => undef }, {}), 'is_deeply(): hashes of undefs');
ok(!_is_deeply(\42,  \23),  'is_deeply(): scalar refs');
ok(!_is_deeply([],   \23),  'is_deeply(): mixed scalar and array refs');
ok(!_is_deeply($a1,  $b1),  'is_deeply(): deep scalar refs');
ok(!_is_deeply($foo, $bar), 'is_deeply(): deep structures');
$b3 = 42;
$foo->{that}{foo} = 42;
ok(_is_deeply('foo', 'foo'), 'is_deeply(): different plain strings');
ok(_is_deeply({}, {}), 'is_deeply(): two empty hashes');
ok(_is_deeply([], []), 'is_deeply(): two empty arrays');
ok(_is_deeply({ this => 42 }, { this => 42 }), 'is_deeply(): same hashes');
ok( _is_deeply([ 1 .. 9 ], [ 1 .. 9 ]),
    'is_deeply(): arrays of different length'
);
ok(_is_deeply([ undef, undef ], [ undef, undef ]),
    'is_deeply(): arrays of undefs');
ok(_is_deeply({ foo => undef }, { foo => undef }),
    'is_deeply(): hashes of undefs');
ok(_is_deeply(\42,  \42),  'is_deeply(): scalar refs');
ok(_is_deeply($a1,  $b1),  'is_deeply(): deep scalar refs');
ok(_is_deeply($foo, $bar), 'is_deeply(): deep structures');
