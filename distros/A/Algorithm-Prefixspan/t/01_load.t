use Test::More tests => 1;
use Algorithm::Prefixspan;

my $data = [
            "a c d",
            "a b c",
            "c b a",
            "a a b",
           ];
my $prefixspan = Algorithm::Prefixspan->new(
                                 data => $data,
                                );

isa_ok $prefixspan, 'Algorithm::Prefixspan';
diag( "loading prefixspan object" );
