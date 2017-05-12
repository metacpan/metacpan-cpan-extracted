use strict;
use warnings;

use Test::More tests => 3;

use lib 't/apps/Foo/lib';

use Foo;
use Dancer::Test appdir => 't/apps/Foo/'; 

response_content_is '/' => "\n<h1>hi there</h1>", 
    "template recognized";

response_content_is '/layout' =>
    "\n<html>\n<h1>hi there</h1>\n</html>", 
    "with layout";

response_content_is '/bad_layout' => '', 
    "with bad layout";
