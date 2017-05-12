use strict;
use warnings;
use utf8;
use Test::More;
use Test::Deep;
use Data::NestedParams;

cmp_deeply(
    collapse_nested_params({ a => undef }),
    { a => undef },
);

cmp_deeply(
    collapse_nested_params({ a => 3 }),
    { a => 3 },
);

cmp_deeply(
    collapse_nested_params({ a => [qw(x y z)] }),
    { 'a[]' => 'x', 'a[]' => 'y', 'a[]' => 'z'},
);

cmp_deeply(
    collapse_nested_params({ a => { b => 3 } }),
    { 'a[b]' => '3'},
);

cmp_deeply(
    collapse_nested_params({'x' => {'y' => [{'z' => '1','w' => 'a'},{'z' => '2','w' => '3'}]}}),
    {'x[y][][z]',1,'x[y][][w]','a','x[y][][z]',2,'x[y][][w]',3}
);

done_testing;

