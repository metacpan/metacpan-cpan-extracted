use strict;
use warnings;
use Test::More;
use Acme::Ford::Prefect2;

is( Acme::Ford::Prefect2::answer(), 42, 'Ford Prefect knows the answer' );

done_testing;
