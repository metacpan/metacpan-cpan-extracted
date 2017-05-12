#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 11;

use lib qw(./lib ../lib t/lib);

use TestController;

use_ok('Bootylicious::Plugin::AjaxLibLoader');

my %ajax_lib_cfg = (
	"jquery"           => "on",
	"jquery_version"   => "1.3.2",
	"jquery_path"      => "all",
	"ext_core"         => "on",
	"ext_core_version" => "3.0.0",
	"ext_core_path"    => "all",
	"dojo"             => "on",
	"dojo_version"     => "1.3.2",
	"dojo_path"        => 'test',
	"mootools"         => "on",
	"mootools_version" => "1.2.3",
	"mootools_path"    => "test2"
  );



my $c = TestController->new;

$c->app->plugins->namespaces(['Mojolicious::Plugin','Bootylicious::Plugin']);
$c->app->plugin('ajax_lib_loader', \%ajax_lib_cfg);
$c->res->body('<head></head><body></body>');
$c->app->plugins->run_hook('after_dispatch', $c);

like(
	$c->res->body,
qr{<script src="http://ajax.googleapis.com/ajax/libs/jquery/1.3.2/jquery.min.js"></script>},
	'JQuery'
);
like(
	$c->res->body,
qr{<script src="http://ajax.googleapis.com/ajax/libs/ext-core/3.0.0/ext-core.js"></script>},
	'Ext-Core'
);
unlike(
	$c->res->body,
qr{<script src="http://ajax.googleapis.com/ajax/libs/dojo/1.3.2/dojo/dojo.xd.js"></script>},
	'not Dojo - only for /test.*/'
);
unlike(
	$c->res->body,
qr{<script src="http://ajax.googleapis.com/ajax/libs/mootools/1.2.3/mootools-yui-compressed.js"></script>},
	'not Mootools - only for /test2'
);

#diag($c->res->body);

#now url path eq '/test'
$c->req->url->path('/test');
$c->res->body('<head></head><body></body>');
$c->app->plugins->run_hook('after_dispatch', $c);

like(
	$c->res->body,
qr{<script src="http://ajax.googleapis.com/ajax/libs/jquery/1.3.2/jquery.min.js"></script>},
	'JQuery'
);
like(
	$c->res->body,
qr{<script src="http://ajax.googleapis.com/ajax/libs/ext-core/3.0.0/ext-core.js"></script>},
	'Ext-Core'
);
like(
	$c->res->body,
qr{<script src="http://ajax.googleapis.com/ajax/libs/dojo/1.3.2/dojo/dojo.xd.js"></script>},
	'now Dojo - only for /test.*/'
);
unlike(
	$c->res->body,
qr{<script src="http://ajax.googleapis.com/ajax/libs/mootools/1.2.3/mootools-yui-compressed.js"></script>},
	'not Mootools - only for /test2'
);

$c->req->url->path('/test2');
$c->res->body('<head></head><body></body>');
$c->app->plugins->run_hook('after_dispatch', $c);
like(
	$c->res->body,
qr{<script src="http://ajax.googleapis.com/ajax/libs/dojo/1.3.2/dojo/dojo.xd.js"></script>},
	'now Dojo - only for /test.*/'
);
like(
	$c->res->body,
qr{<script src="http://ajax.googleapis.com/ajax/libs/mootools/1.2.3/mootools-yui-compressed.js"></script>},
	'now Mootools - only for /test2'
);

#diag($c->res->body);
