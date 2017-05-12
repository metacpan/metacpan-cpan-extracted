#!/usr/bin/perl -w

use strict;
use Test::More 'no_plan';
use Inline 'WebChat';

ok(hello(), "hello.pl should be reachable and working");

__END__

__WebChat__

sub hello {
    GET http://localhost/formmagick/examples/hello.pl
        EXPECT OK
        F name=Sam
        CLICK Finish
            EXPECT OK && /Hello, Sam/
}
