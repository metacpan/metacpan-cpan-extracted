use strict;
use warnings;

use Test::More;

BEGIN {
    require Dancer; 
    plan skip_all => 'Dancer 2 tests'
        if Dancer->VERSION < 2;
}

{
package Foo;
use Dancer ':syntax';

set appname => 'Foo';

set engines => {
    template => {
        mason => { 
            default_escape_flags => [ 'h' ],
            extension => 'm',
        },
    }
};

set template => 'mason';

get '/' => sub {
    template 'index';
};

true;
}

plan tests => 1;

use Dancer::Test 'Foo';

response_content_like [GET => '/'], qr/&lt;escape&gt;/, 
    "escape config was passed";

