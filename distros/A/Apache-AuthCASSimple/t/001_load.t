# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 1;
#use Apache::Test ':withtestmore';
#use Apache::TestUtil;
#use Apache::TestRequest qw(GET POST GET_BODY);


BEGIN { use_ok( 'Apache::AuthCASSimple' ); }

#my $object = Apache::AuthCASSimple->handler ();
#isa_ok ($object, 'Apache::AuthCASSimple');


