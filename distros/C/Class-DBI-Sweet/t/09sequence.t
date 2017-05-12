use strict;
use warnings;

use Test::More;

my $lib;

if ( $^O eq 'MSWin32' ) {
    $lib = 'Win32API::GUID';
}
else {
    $lib = 'Data::UUID';
}

eval "require $lib;";
plan skip_all => "Need $lib for this test" if $@;

eval "use DBD::SQLite";
plan skip_all => 'needs DBD::SQLite for testing' if $@;

plan tests => 2;

use lib 't/lib';

use_ok('SweetTest');

SweetTest::CD->sequence( 'uuid' );

like( SweetTest::CD->_next_in_sequence, 
    qr/^\w{8}-\w{4}-\w{4}-\w{4}-\w{12}$/, "uuid ok" );
