use Test::More tests => 3;
BEGIN { use_ok('CGI::Application::Plugin::DetectAjax'); };


use lib './t';
use strict;


$ENV{CGI_APP_RETURN_ONLY} = 1;

use TestAppBasic;
my $t1_obj = TestAppBasic->new();
my $t1_output = $t1_obj->run();

is($t1_obj->is_ajax, 0);

$ENV{HTTP_X_REQUESTED_WITH} = 'xmlhttprequest';



is($t1_obj->is_ajax, 1);
