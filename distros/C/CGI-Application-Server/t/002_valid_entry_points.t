#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 22;
use Test::Exception;

BEGIN {
    use_ok('CGI::Application::Server');
}

=pod

This could probably use some more tests, but it 
is good enough for now (i.e. - covers the bug 
which prompted this fix)

=cut

my $server = CGI::Application::Server->new();
isa_ok($server, 'CGI::Application::Server');
isa_ok($server, 'HTTP::Server::Simple');

$server->entry_points({
    '/foo'         => 'Foo',
    '/foo/bar'     => 'Foo::Bar',    
    '/foo/bar/baz' => 'Foo::Bar::Baz',    
});

foreach my $uri (qw(
        /foo
        /foo?say=hello
        /foo/bling/bar
        /foo/?bar=baz
        /foo/barr
    )) {
    is($server->is_valid_entry_point($uri), 'Foo', '... got Foo where we expected');
}

foreach my $uri (qw(
        /foo/bar
        /foo/bar?say=hello
        /foo/bar/bling/bar
        /foo/bar/?bar=baz    
        /foo/bar/bazz        
    )) {
    is($server->is_valid_entry_point($uri), 'Foo::Bar', '... got Foo::Bar where we expected');
}

foreach my $uri (qw(
        /foo/bar/baz
        /foo/bar/baz?say=hello
        /foo/bar/baz/bling/bar
        /foo/bar/baz/?bar=baz 
        /foo/bar/baz/../
    )) {
    is($server->is_valid_entry_point($uri), 'Foo::Bar::Baz', '... got Foo::Bar::Baz where we expected');
}

foreach my $uri (qw(
        /fooo
        /food?say=hello
        /fooo/bar
        /fooo/barr/baz
    )) {
    is($server->is_valid_entry_point($uri), undef, '... got undef where we expected');
}


