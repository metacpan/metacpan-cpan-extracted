use Test2::V0 -no_srand => 1;
use Acme::Alien::DontPanic;
use Acme::Ford::Prefect;

is( Acme::Ford::Prefect::answer(), 42, 'Ford Prefect knows the answer' );

done_testing;
