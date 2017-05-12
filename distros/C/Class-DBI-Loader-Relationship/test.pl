use Test::More 'no_plan';
use_ok("Class::DBI::Loader::Relationship");
use Class::DBI::Loader::Generic;

my $fake = bless {
    CLASSES => { reverse(
        BeerDB::Brewery => "brewery",
        BeerDB::Beer => "beer",
        BeerDB::Handpump => "handpump",
        BeerDB::Pub => "pub"
    )
    }
}, 'Class::DBI::Loader::Generic';

$Class::DBI::Loader::Relationship::DEBUG = 1;

my $crib1 = <<EOF;
BeerDB::Brewery->has_many(beers => BeerDB::Beer);
BeerDB::Beer->has_a(brewery => BeerDB::Brewery);
EOF
sub test { my($text, $crib) = @_; is($fake->relationship($text), $crib, $text)}

test("a brewery produces beers", $crib1);
test("breweries produce beer", $crib1);
test("a brewery has a beer", "BeerDB::Brewery->has_a(beer => BeerDB::Beer);\n");

my $crib2 = <<EOF;
BeerDB::Handpump->has_a(pub => BeerDB::Pub)
BeerDB::Handpump->has_a(beer => BeerDB::Beer)
BeerDB::Pub->has_many(beers => [ BeerDB::Handpump => beer ])
BeerDB::Beer->has_many(pubs => [ BeerDB::Handpump => pub ])
EOF

test("pubs have beer on handpumps", $crib2);
