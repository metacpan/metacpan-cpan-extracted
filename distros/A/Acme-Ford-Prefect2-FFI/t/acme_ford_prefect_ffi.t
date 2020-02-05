use Test2::V0 -no_srand => 1;
use 5.008001;
use Acme::Ford::Prefect2::FFI;

note "dll = $Acme::Ford::Prefect2::FFI::dll";

is( Acme::Ford::Prefect2::FFI::answer(), 42, 'Ford Prefect knows the answer' );

done_testing;
