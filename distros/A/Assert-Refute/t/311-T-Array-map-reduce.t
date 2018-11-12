#!perl

use strict;
use warnings;
BEGIN{ delete @ENV{qw(NDEBUG PERL_NDEBUG)} };
use Test::More;

use Assert::Refute;
use Assert::Refute::Contract qw(contract);

my $map = contract {
    package T;
    use Assert::Refute::T::Array;
    map_subtest { $_[0]->like( $_, qr/\d/, "THIS TEST FAILED IF YOU SEE THIS" ); } shift, "subtest";
};

contract_is $map->apply([]), "t1d", "map empty = pass";
contract_is $map->apply([1..5]), "t1d", "map happy case";

contract_is $map->apply(["a", "z"]), "tNd", "map failed test";

note "REPORT";
note $map->apply(["a", 24, "z"])->get_tap;
note "/REPORT";

my $reduce = contract {
    package T;
    reduce_subtest {
        $_[0]->cmp_ok( $a->{end}, "==", $b->{start}, "FAILED IF YOU SEE THIS" );
    } shift;
};

contract_is $reduce->apply([]), "t1d", "empty array ok";
contract_is $reduce->apply([{start => 0, end => 0}]), "t1d", "1-elem array ok";

contract_is $reduce->apply([
    {start => 1, end => 2},
    {start => 2, end => 3},
    {start => 3, end => 4},
]), "t1d", "reduce happy case";

my $reduce_fail = $reduce->apply([
    {start => 1, end => 3},
    {start => 2, end => 3},
    {start => 3, end => 3},
    {start => 4, end => 3},
]);

is $reduce_fail->get_sign, "tNd", "1 failing test";

note "REPORT\n".$reduce_fail->get_tap."/REPORT";

done_testing;
