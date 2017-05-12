use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use Test::More;

BEGIN {
  $ENV{TESTAPP_CONFIG_ETC} = "$FindBin::Bin/etc/conf/local.yml";
}

use Catalyst::Test 'TestApp' ;

{
  is( request( 'http://localhost/test/scalar' )->content, 'meh local', "local" );
  is( request( 'http://localhost/test/array' )->content, '["boooo", "beeee", "barrr"]', "local" );
  is( request( 'http://localhost/test/hash' )->content, '{ foo => "bar", xx => "yyay" }', "test+local" );
}

done_testing();
