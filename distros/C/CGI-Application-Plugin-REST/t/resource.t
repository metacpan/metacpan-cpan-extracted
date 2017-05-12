#!/usr/bin/perl

# Test rest_resource()
use strict;
use warnings;
use English qw( -no_match_vars );
use Test::More tests => 21;
use Test::WWW::Mechanize::CGIApp;
use lib 't/lib';
use Test::CAPRESTResource;

my $mech = Test::WWW::Mechanize::CGIApp->new;

$mech->app(
    sub {
        my $app = Test::CAPRESTResource->new(PARAMS => {

        });
        $app->run();
    }
);
$mech->add_header(Accept => 'text/html;q=1.0, */*;q=0.1');

eval {
    $mech->get('http://localhost/?noargs=1');
};
ok(defined $EVAL_ERROR, 'no args');

eval {
    $mech->get('http://localhost/?bogusargs=1');
};
ok(defined $EVAL_ERROR, 'bogus args');

eval {
    $mech->get('http://localhost/?bogusresource=1');
};
ok(defined $EVAL_ERROR, 'bogusresource');

eval {
    $mech->get('http://localhost/?bogusintypes=1');
};
ok(defined $EVAL_ERROR, 'bogus in_types');

eval {
    $mech->get('http://localhost/?bogusouttypes=1');
};
ok(defined $EVAL_ERROR, 'bogus out_types');

$mech->post('http://localhost/widget');
$mech->title_is('widget create', 'widget_create');

$mech->post('http://localhost/widget/1?_method=DELETE');
$mech->title_is('widget destroy 1', 'widget_destroy');

$mech->get('http://localhost/widget/2/edit');
$mech->title_is('widget edit 2', 'widget_edit');

$mech->get('http://localhost/widget');
$mech->title_is('widget index', 'widget_index');

$mech->get('http://localhost/widget/new');
$mech->title_is('widget new', 'widget_new');

$mech->get('http://localhost/widget/3');
$mech->title_is('widget show 3', 'widget_show');

$mech->put('http://localhost/widget/4', content_type => 'text/html');
$mech->title_is('widget update 4', 'widget_update');

$mech->post('http://localhost/widget?_method=OPTIONS');
$mech->title_is('widget options', 'widget_options');

$mech->post('http://localhost/fidget', content_type => 'application/xml');
$mech->title_is('foo create', 'foo_create');

$mech->post('http://localhost/fidget/1?_method=DELETE');
$mech->title_is('foo destroy 1', 'foo_destroy');

$mech->get('http://localhost/fidget/2/edit');
$mech->title_is('foo edit 2', 'foo_edit');

$mech->get('http://localhost/fidget');
$mech->title_is('foo index', 'foo_index');

$mech->get('http://localhost/fidget/new');
$mech->title_is('foo new', 'foo_new');

$mech->get('http://localhost/fidget/3');
$mech->title_is('foo show 3', 'foo_show');

$mech->put('http://localhost/fidget/4', content_type => 'application/xml');
$mech->title_is('foo update 4', 'foo_update');

$mech->put('http://localhost/fidget/4', content_type => 'text/html');
is($mech->status, '415', 'unacceptable mime type');
