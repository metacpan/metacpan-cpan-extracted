#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 14;
use Test::Exception;

package main;

BEGIN {
    use_ok('CGI::Application::Server');
}

=pod

This could probably use some more tests, but it 
is good enough for now.

=cut

my $server = CGI::Application::Server->new();
isa_ok($server, 'CGI::Application::Server');
isa_ok($server, 'HTTP::Server::Simple');

$server->entry_points({
    '/'            => 'TopLevel',
    '/foo'         => 'Foo',
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
        /
        /fooo
        /fooo/
        /food?say=hello
        /fooo/bar
        /fooo/barr/baz
    )) {
    is($server->is_valid_entry_point($uri), 'TopLevel', '... got TopLevel where we expected');
}


