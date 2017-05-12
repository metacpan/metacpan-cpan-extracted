use strict;
use Test::More;

use Data::Enumerator qw/
    independ
    range
    pattern
    generator
    
/;
my $pattern1 = pattern(qw/a b c/);
my $pattern2 = pattern(qw/x y z/);

my $gen = generator(
    {   p1 => $pattern1,
        p2 => [$pattern2],
        p3 => { x => [ pattern(qw/a b c/) ] },
    }
)->limit( 2, 5 );

is_deeply(
    [ $gen->list ],
    [   { p1 => "c", p2 => ["x"], p3 => { "x" => ["a"] } },
        { p1 => "a", p2 => ["x"], p3 => { "x" => ["b"] } },
        { p1 => "b", p2 => ["x"], p3 => { "x" => ["b"] } },
        { p1 => "c", p2 => ["x"], p3 => { "x" => ["b"] } },
        { p1 => "a", p2 => ["x"], p3 => { "x" => ["c"] } },
    ]
);
{
    my $count = 1;
    my $gen = generator(
        {   sex  => pattern(qw/male female/),
            age  => range( 15, 99, 5 ),
            id   => independ( pattern(qw/1 2 3 4 5/)->repeat ),
            from => pattern(qw/pc touch mobile/),
            test => 10,
        }
    );
    is( scalar $gen->list, 102 );

}
::done_testing;
