use warnings;
use strict;

use Test::More;

BEGIN { plan tests => 10 }

use lib "../lib";
BEGIN { use_ok("Data::DefGen", qw(def)); }

# call context
{
    my $d = def { }->gen;
    is( $d, undef, "scalar context 1" );

    $d = def { (11, 22, 33) }->gen;
    is( $d, 33, "scalar context 2" );

    my @a = def { }->gen;
    is_deeply( \@a, [ ], "list context 1" );

    @a = def { (11, 22, 33) }->gen;
    is_deeply( \@a, [11, 22, 33], "list context 2" );

    my %h = def { qw(a b), def { qw(c d e) }, "f" }->gen;
    is_deeply( \%h, {a => "b", c => "d", e => "f"}, "list context 3" );
}

# params passing
{
    my @captured;

    my $i = -1;
    my $catch = sub { push @{ $captured[++$i] }, @_ };

    my @params = ("foo", 127, {6..9}, [3..6]);

    def {
        $catch->(@_);

        return (
            {
                foo => def { $catch->(@_) },
                bar => [23, def { $catch->(@_); [def { $catch->(@_) }] }, 89],
            },
            def { $catch->(@_) },
        );
    }->gen(@params);

    is( $i, 4, "params sanity" );
    is_deeply( \@captured, [map { \@params } 0 .. $i], "params passed" );
}

# nesting
{
    my @src1 = qw(abc cde efg);
    my @src2 = (66, 77, 88);
    my @src3 = ([1, 1], [2, 3], [5, 8]);
    my $i = 0;

    my $defn = def {
        return {
            foo => "bar",
            baz => def {
                return {
                    qux => [
                        shift(@src1),
                        def { [++$i, shift(@src2)] },
                        shift(@src3),
                    ],
                };
            },
        };
    };

    my @datas = def { ($defn) x 3 }->gen;

    is_deeply( \@datas, [{
        foo => "bar",
        baz => {
            qux => ["abc", [1, 66], [1, 1]],
        },
    }, {
        foo => "bar",
        baz => {
            qux => ["cde", [2, 77], [2, 3]],
        },
    }, {
        foo => "bar",
        baz => {
            qux => ["efg", [3, 88], [5, 8]],
        },
    }], "nesting" );
}

# object cloning
{
    my $defn = def {
        return (
            (bless {attr1 => "Foo clone"}, "Foo"),
            def { ["bar", (bless {attr2 => "Baz clone"}, "Baz")] }
              obj_cloner => sub { shift->{attr2} },
        );
    } obj_cloner => sub { shift->{attr1} };

    is_deeply( [$defn->gen], ["Foo clone", ["bar", "Baz clone"]], "object clone" );
}
