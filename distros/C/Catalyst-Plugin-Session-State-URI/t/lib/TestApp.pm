package TestApp;

use strict;
use Catalyst qw/
    Session
    Session::Store::Dummy
    Test::Errors 
    Test::Headers 
    Test::Plugin
/;
use Catalyst::Utils;

our $VERSION = '0.01';

__PACKAGE__->config(
    name => __PACKAGE__,
    root => '/some/dir',
    session => {
        param => 'sid',
        rewrite_body => 0,
        rewrite_redirect => 0,
    }
);

TestApp->setup(qw/Session::State::URI/);

{
    no warnings 'redefine';
    sub Catalyst::Log::error { }
}
1;
