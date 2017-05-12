#!D:\workspace\perl\perl\bin\perl.exe -w
use strict;
use warnings;
use Test::More;

BEGIN { use_ok 'Catalyst::Test', 'MyApp' }

ok( request('/')->is_success, 'Request should succeed' );

done_testing();
