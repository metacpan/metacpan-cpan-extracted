#!perl 

use strict;
use Test::More;
use FindBin;

BEGIN {
    use_ok( 'Data::Validate::WithYAML' );
}

my $validator = Data::Validate::WithYAML->new( $FindBin::Bin . '/test2.yml' );
my $message   = $validator->message( 'password' );
is $message, 'Test';

is $validator->message( 'does_not_exist' ), '';

done_testing();
