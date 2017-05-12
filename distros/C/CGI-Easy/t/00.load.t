use warnings;
use strict;
use Test::More tests => 5;

BEGIN {
    for (qw(    CGI::Easy
                CGI::Easy::Request
                CGI::Easy::Headers
                CGI::Easy::Session
                CGI::Easy::Util     )) {
        use_ok($_) or BAIL_OUT("unable to load module $_")
    }
}

diag( "Testing CGI::Easy $CGI::Easy::VERSION, Perl $], $^X" );
