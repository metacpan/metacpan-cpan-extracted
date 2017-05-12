use Test::More;
use Biblio::Citation::Compare;
use utf8;

my %tests = (
    "the second edition" => 2,
    "the 2nd edition" => 2,
    "the 3rd edition" => 3,
    "the 2ieme edition" => 2,
    "title V. 2" => 2,
    "title V.2: bla" => 2,
    "title 2: bla" => 2,
    "title V X" => 10,
    "3ieme éd." => 3,
    "A title with I in the middle" => undef,
    "no edition" => undef,
);

for my $k (sort keys %tests) {
    is(Biblio::Citation::Compare::extractEdition($k),$tests{$k},"$k => $tests{$k}");
}

