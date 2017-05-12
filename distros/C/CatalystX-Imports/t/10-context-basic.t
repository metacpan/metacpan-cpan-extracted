#!perl
use warnings;
use strict;

use FindBin;
use lib "$FindBin::Bin/lib";

use Test::More;

use CatalystX::Imports::Context::Default ();
BEGIN {
    CatalystX::Imports::Context::Default->register_export(
        name =>'prototype_test',
        code => sub {
            my ($library, $self, $c, $a_args, $code) = @_;
            return $code->();
        },
        prototype => '&',
    );
}

use Catalyst::Test 'TestApp';
use HTTP::Request;

my @test_data = (
    ['captures',        '/1/2/3/test_captures',     '1, 2, 3; 3'],
    ['action',          undef,                      'basic/test_action; basic/base; basic/base; Catalyst::Action'],
    ['uri_for',         undef,                      'http://localhost/3/4/5/test_captures/foo?x=7'],
    ['model',           undef,                      23],
    ['model w/ prefix', '/test_model_w_prefix',     'Prefix_Foo'],
    ['model w/ AC',     '/test_model_withac/1/2/3', '1, 2, 3'],
    ['response',        undef,                      1],
    ['request',         undef,                      1],
    ['has_param #t',    '/test_has_param?foo=12',   1],
    ['has_param #f',    '/test_has_param',          0],
    ['param',           '/test_param?foo=12',       12],
    ['path_to',         undef,                      '/some/dir/root/foo/bar'],
    ['stash',           '/test_stash?foo=23',       23],
    ['exported config', '/test_config',             'BAZ'],
    ['aliased config',  '/test_config_alias',       40],
    ['args',            '/a/b/test_args/1/2/3',     'a, b; 1, 2, 3; x, y, z'],
    ['passed_args',     '/test_passed_args/1/2/3',  '1, 2, 3'],
);

my @exports = keys %{ CatalystX::Imports::Context::Default->_export_map };

plan tests => (scalar(@test_data) * 2) + scalar(@exports) + 7;

for (@test_data) {
    my ($name, $path, $content) = @$_;
    $path ||= "/test_$name";
    ok( my $response = request( "http://localhost$path" ), "$name request ok" );
    is( $response->content, $content, "$name function result ok" );
}

for (@exports) {
    no strict 'refs';
    my $sym = *{ "TestApp::Controller::Basic::$_" }{CODE};
    ok( !$sym, "function '$_' removed after compiletime" );
}

for (qw(action uri_for captures)) {
    ok( my $method = TestApp::Controller::Basic->can($_), "method '$_' available" );
    is( $method->(), 23, "method '$_' is correct one" );
}

is( $TestApp::Controller::Basic::PROTOTYPE_TEST, '&',
    'prototype setting works' );
