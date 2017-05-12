#!perl 

use strict;
use Test::More tests => 2;
use Data::Dumper;
use FindBin;

BEGIN {
    use_ok( 'Data::Validate::WithYAML' );
}

my $validator = Data::Validate::WithYAML->new( $FindBin::Bin . '/test2.yml' );
my $message   = $validator->message( 'password' );
is( $message, 'Test' );
