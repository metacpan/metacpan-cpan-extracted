#!/usr/bin/perl
# 01-live.t 
# Copyright (c) 2006 Jonathan Rockway <jrockway@cpan.org>

use Test::More tests => 12;
use FindBin qw($Bin);
use lib "$Bin/lib";
BEGIN {
    $ENV{TESTAPP_foo} = 'foo';
    $ENV{TESTAPP_bar} = 'bar';
    $ENV{TESTAPP_foo_bar_baz} = 'quux';
    $ENV{TESTAPP_quux} = q%[1,2,3,4]%;
    $ENV{TESTAPP_View::TestView_foo} = "Test View's foo!";
    $ENV{TESTAPP_View::TestView_quux} = q%[1,2,3,"Test View's quux!",{"foo":"bar"}]%;
    $ENV{TESTAPP_View__TestView_bar} = "Test View's bar!";
    $ENV{TESTAPP_Model__TestModel} = q%{"bar":"baz"}%;
    
}

use Catalyst::Test 'TestApp';

ok(my $r = request('/'), 'request /');
ok($r->is_success, 'that worked');

my $config = eval $r->content;
ok(ref $config, 'got config');

is($config->{foo}, 'foo', 'got foo');
is($config->{bar}, 'bar', 'got bar');
is($config->{foo_bar_baz}, 'quux', 'got foo_bar_baz');
is_deeply($config->{quux}, [1,2,3,4], 'JSON for simple param');

my $view = get('/foo/foo');
is($view, "Test View's foo!", 'got View::TestView->foo');

$view = get('/foo/bar');
is($view, "Test View's bar!", 'got View::TestView->bar');

$view = get('/foo/quux');
eval $view;
no warnings 'once';
is_deeply($quux, [1,2,3,"Test View's quux!",{ foo => 'bar'}], 
          'JSON for :: sub-param');

$r = request('/model');
ok($r->is_success, 'got /model');
my $model_attributes = eval $r->content;
is_deeply($model_attributes,
          {
              foo => 'bar', # From __PACKAGE__ default config
              bar => 'baz', # Merged from my environment hash,
              catalyst_component_name => 'TestApp::Model::TestModel',
          },
          'JSON for top-level :: param with hash merge');
