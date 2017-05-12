use Test::More;
use Test::Exception;

BEGIN {
    use_ok 'Convert::EDS::XDD', 'eds2xdd';
}

throws_ok( sub { eds2xdd('DOES_NOT_EXIST') }, qr/failed/i );


done_testing;


