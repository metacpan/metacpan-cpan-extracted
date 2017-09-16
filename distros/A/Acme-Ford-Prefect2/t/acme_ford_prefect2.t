use Test2::V0 -no_srand => 1;
use Acme::Ford::Prefect2;

is( Acme::Ford::Prefect2::answer(), 42, 'Ford Prefect knows the answer' );

done_testing;
