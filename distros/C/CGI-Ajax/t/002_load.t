# -*- perl -*-

# t/002_load.t - check module loading and create testing directory

use Test::More tests => 2;

BEGIN { use_ok( 'CGI::Ajax' ); }

my $object = CGI::Ajax->new ( 'myfunc' => '');
isa_ok ($object, 'CGI::Ajax');
