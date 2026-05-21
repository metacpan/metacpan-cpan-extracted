use v5.36;

use Test::More;

use utf8;

use Config;

plan skip_all => 'Only 64 bit systems are supported.'  unless $Config{ptrsize} && $Config{ptrsize} == 8;
plan tests => 271;

require Chess4p;

use Chess4p::Common qw(:all);

# Test iteration over the squares represented by a bitboard (a 64 bit integer).
# Obviously, the tests of Board should fail if the iterator function was incorrect.
# But when trying out alternative implementations, it's very handy to have a focused
# test.

my @tests;

push @tests,
  [A1],
  [A1, B1],
  [B1, A1],
  [A1, B2, G7, H7],
  [D4, E4, C3, G6, F4, A7, B8],
  ;

for my $test (@tests) {
    # make a bb from the squares
    my $bb = Chess4p::Board::_make_bb(@$test);
    my @squares;
    # collect the squares by iterating over the bb
    while ($bb) {
        my $sqr = Chess4p::Board::_pop_lsb_index(\$bb);
        push @squares, $sqr;
    }

    # verify the arrays are equivalent
    is_deeply([sort @squares], [sort @$test], 'arrays are equivalent');
}


# testing single bits

for my $i (0 .. 63) {
    my $bb = Chess4p::Board::_make_bb($i);
    is(Chess4p::Board::_pop_lsb_index(\$bb), $i, "single bit $i");
    is($bb, 0, "bit $i was cleared");
}

# test different implementations are equivalent

for my $i (0 .. 63) {
    my $bb_old = Chess4p::Board::_make_bb($i);
    my $bb_new = Chess4p::Board::_make_bb($i);

    my $old = Chess4p::Board::_pop_lsb_index_old(\$bb_old);
    my $new = Chess4p::Board::_pop_lsb_index(\$bb_new);

    is($new, $old, "same square for bit $i");
    is($bb_new, $bb_old, "same remaining bb for bit $i");
}

# the next test specifically tests iteration order

@tests = (
    [A1],
    [A1, B1],
    [B1, A1],
    [A1, B2, G7, H7],
    [D4, E4, C3, G6, F4, A7, B8],
);

for my $test (@tests) {
    my $bb_old = Chess4p::Board::_make_bb(@$test);
    my $bb_new = Chess4p::Board::_make_bb(@$test);

    my @old;
    my @new;

    while ($bb_old) {
        push @old, Chess4p::Board::_pop_lsb_index_old(\$bb_old);
    }

    while ($bb_new) {
        push @new, Chess4p::Board::_pop_lsb_index(\$bb_new);
    }

    is_deeply(\@new, \@old, "same pop order for @$test");
    is($bb_new, $bb_old, "same final bb for @$test");
}


done_testing;
