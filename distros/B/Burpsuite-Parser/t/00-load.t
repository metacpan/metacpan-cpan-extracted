#!perl -T

use Test::More tests => 4;
BEGIN {
    use_ok( 'Burpsuite::Parser' );
    use_ok( 'Burpsuite::Parser::Issue' );
    use_ok( 'Burpsuite::Parser::Session' );
    use_ok( 'Burpsuite::Parser::ScanDetails' );
}
