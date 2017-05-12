use strict;
use warnings;

use Test::More;

BEGIN {
    require Dancer; 
    plan skip_all => 'Dancer 1 tests'
        if Dancer->VERSION >= 2;
}

plan tests => 1;

use lib 't/apps/Foo/lib';

use Foo;
use Dancer::Test appdir => 't/apps/Foo/yadah';  # ... this ain't right

response_content_like [GET => '/'], qr/&lt;escape&gt;/, 
    "escape config was passed";

