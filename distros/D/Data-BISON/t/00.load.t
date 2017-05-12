use Test::More tests => 4;

BEGIN {
    use_ok( 'Data::BISON' );
    use_ok( 'Data::BISON::Decoder' );
    use_ok( 'Data::BISON::Encoder' );
    use_ok( 'Data::BISON::yEnc' );
}

diag( "Testing Data::BISON $Data::BISON::VERSION" );
