use Test::More tests=>10;
use Test::Exception;
use Acme::Geo::Whitwell::Name;

eval "use Test::Exception";
plan skip_all => "Test::Exception required to check expected failures" if $@;

dies_ok { Acme::Geo::Whitwell::Name::_vowel_build("BLORP") } 
        "unparseable coordinate";
like $@, qr/'BLORP' does not look like a proper coordinate/,
         "right message";

dies_ok { Acme::Geo::Whitwell::Name::_vowel_build("35neSw") }
        "conflicting indicators";
like $@, qr/Multiple conflicting sign indicators detected in '35neSw'/,
         "right message";

dies_ok { Acme::Geo::Whitwell::Name::_vowel_build("35ne") }
        "multiple positive indicators";
like $@, qr/Multiple sign indicators detected in '35ne'/,
         "right message";

dies_ok { Acme::Geo::Whitwell::Name::_vowel_build("35SW") }
        "multiple negative indicators";
like $@, qr/Multiple sign indicators detected in '35SW'/,
         "right message";

dies_ok { Acme::Geo::Whitwell::Name::_vowel_build("-35N") }
         "sign and indicator don't match";
like $@, qr/Multiple conflicting sign indicators detected in '-35N'/,
         "right message";
