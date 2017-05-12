use strict;
use warnings;
use Test::More;

my $class;
BEGIN {
    use_ok($class='t::SimpleUsage', qw(Left Right));
}

# ----
# Helpers.

# ----
# Tests.
subtest 'default properties' => sub {
    is(Left ->name, 'Left' , 'Left ->name');
    is(Right->name, 'Right', 'Right->name');

    is(Left ->ordinal, 0, 'Left ->ordinal');
    is(Right->ordinal, 1, 'Right->ordinal');

    is(Left ->is_left ,  1, 'Left ->is_left');
    is(Left ->is_right, '', 'Left ->is_right');
    is(Right->is_left , '', 'Right->is_left');
    is(Right->is_right,  1, 'Right->is_right');
};

subtest 'compare by ordinal' => sub {
    is(Left()  <=> Right, -1, 'Left  <=> Right');
    is(Left()  <=> Left ,  0, 'Left  <=> Left');
    is(Right() <=> Right,  0, 'Right <=> Right');
    is(Right() <=> Left ,  1, 'Right <=> Left');

    is(Left()  < Left , '', 'Left  < Left');
    is(Left()  < Right,  1, 'Left  < Right');
    is(Right() < Left , '', 'Right < Left');
    is(Right() < Right, '', 'Right < Right');

    is(Left()  <= Left ,  1, 'Left  <= Left');
    is(Left()  <= Right,  1, 'Left  <= Right');
    is(Right() <= Left , '', 'Right <= Left');
    is(Right() <= Right,  1, 'Right <= Right');

    is(Left()  > Left , '', 'Left  > Left');
    is(Left()  > Right, '', 'Left  > Right');
    is(Right() > Left ,  1, 'Right > Left');
    is(Right() > Right, '', 'Right > Right');

    is(Left()  >= Left ,  1, 'Left  >= Left');
    is(Left()  >= Right, '', 'Left  >= Right');
    is(Right() >= Left ,  1, 'Right >= Left');
    is(Right() >= Right,  1, 'Right >= Right');

    is(Left()  == Left ,  1, 'Left  == Left');
    is(Left()  == Right, '', 'Left  == Right');
    is(Right() == Right,  1, 'Right == Right');

    is(Left()  != Left , '', 'Left  != Left');
    is(Left()  != Right,  1, 'Left  != Right');
    is(Right() != Right, '', 'Right != Right');
};

subtest 'compare by name' => sub {
    is(Left()  cmp Right, -1, 'Left  cmp Right');
    is(Left()  cmp Left ,  0, 'Left  cmp Left');
    is(Right() cmp Right,  0, 'Right cmp Right');
    is(Right() cmp Left ,  1, 'Right cmp Left');

    is(Left()  lt Left , '', 'Left  lt Left');
    is(Left()  lt Right,  1, 'Left  lt Right');
    is(Right() lt Left , '', 'Right lt Left');
    is(Right() lt Right, '', 'Right lt Right');

    is(Left()  le Left ,  1, 'Left  le Left');
    is(Left()  le Right,  1, 'Left  le Right');
    is(Right() le Left , '', 'Right le Left');
    is(Right() le Right,  1, 'Right le Right');

    is(Left()  gt Left , '', 'Left  gt Left');
    is(Left()  gt Right, '', 'Left  gt Right');
    is(Right() gt Left ,  1, 'Right gt Left');
    is(Right() gt Right, '', 'Right gt Right');

    is(Left()  ge Left ,  1, 'Left  ge Left');
    is(Left()  ge Right, '', 'Left  ge Right');
    is(Right() ge Left ,  1, 'Right ge Left');
    is(Right() ge Right,  1, 'Right ge Right');

    is(Left()  eq Left ,  1, 'Left  eq Left');
    is(Left()  eq Right, '', 'Left  eq Right');
    is(Right() eq Right,  1, 'Right eq Right');

    is(Left()  ne Left , '', 'Left  ne Left');
    is(Left()  ne Right,  1, 'Left  ne Right');
    is(Right() ne Right, '', 'Right ne Right');
};

subtest 'evaluate as numeric' => sub {
    is(0+Left , 0, '0+Left');
    is(0+Right, 1, '0+Right');
};

subtest 'evaluate as string' => sub {
    is(''.Left , 'Left', q{''.Left});
    is(''.Right, 'Right', q{''.Right});
};

subtest 'class methods' => sub {
    is_deeply([$class->values], [Left, Right], 'values');
    is_deeply([$class->names], [qw(Left Right)], 'names');
    is($class->value_of('Left'), Left, q{value_of('Left')});
    is($class->value_of('Right'), Right, q{value_of('Right')});
    is($class->from_ordinal(0), Left, q{from_ordinal(0)});
    is($class->from_ordinal(1), Right, q{from_ordinal(1)});
};

subtest 'ref type' => sub {
    is(ref Left, $class, 'ref Left');
    is(ref Right, $class, 'ref Right');
};

# ----
done_testing;
