use Test::More tests => 1;
use Algorithm::Prefixspan;

my $data = [
            "a c d",
            "a b c",
            "c b a",
            "a a b",
           ];
my $expected = {
          'c' => 3,
          'a c' => 2,
          'a' => 5,
          'b' => 3,
          'a b' => 2
        };

my $prefixspan = Algorithm::Prefixspan->new(
                                 data => $data,
                                );
my $got = $prefixspan->run;

is_deeply $got, $expected;

diag( "extracting pattern" );
