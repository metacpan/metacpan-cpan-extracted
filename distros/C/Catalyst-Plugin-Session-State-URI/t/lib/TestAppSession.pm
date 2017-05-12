package TestAppSession;

use strict;
use Catalyst qw/
    Test::Errors 
    Test::Headers 
    Test::Plugin
/;
use Catalyst::Utils;

our $VERSION = '0.01';

TestApp->config( name => 'TestApp', root => '/some/dir', session => { param => 'sid', overload_uri_for => 1 } );

TestApp->setup(qw/Session::State::URI/);

{
    no warnings 'redefine';
    sub Catalyst::Log::error { }
}
1;
