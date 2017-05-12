use strict;
use Test::More;

use Data::Enumerator qw/pattern/;
{
    my $hoge = pattern((1..3));
    my $fuga = $hoge->select(sub{$_[0]*2});
    ::is_deeply([$fuga->list],[2,4,6]);
}
{
    my $hoge = pattern((1..15));
    my $fuga = $hoge->limit(1,10);
    ::is_deeply([$fuga->list],[2..11]);
}
{
    my $hoge = pattern( 1 .. 3 )->product( pattern(qw/a b c/) );
    my $fuga = $hoge->select(
        sub {
            my ($value) = @_;
            $value->[1] .= 'hoge';
            return $value;
        }
    );
    ::is_deeply(
        [ $fuga->list ],
        [   [ 1, "ahoge" ],
            [ 1, "bhoge" ],
            [ 1, "choge" ],
            [ 2, "ahoge" ],
            [ 2, "bhoge" ],
            [ 2, "choge" ],
            [ 3, "ahoge" ],
            [ 3, "bhoge" ],
            [ 3, "choge" ],
        ],
    );
}

{
    my $p = pattern(1..3)->product(pattern(1..5))->select([qw/hoge fuga/]);
    is_deeply(
        $p->to_array,
        [   { fuga => 1, hoge => 1 },
            { fuga => 2, hoge => 1 },
            { fuga => 3, hoge => 1 },
            { fuga => 4, hoge => 1 },
            { fuga => 5, hoge => 1 },
            { fuga => 1, hoge => 2 },
            { fuga => 2, hoge => 2 },
            { fuga => 3, hoge => 2 },
            { fuga => 4, hoge => 2 },
            { fuga => 5, hoge => 2 },
            { fuga => 1, hoge => 3 },
            { fuga => 2, hoge => 3 },
            { fuga => 3, hoge => 3 },
            { fuga => 4, hoge => 3 },
            { fuga => 5, hoge => 3 },
        ]
    );
}
::done_testing;
