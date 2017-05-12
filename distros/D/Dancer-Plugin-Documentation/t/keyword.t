#!/usr/bin/env perl

use strict;
use warnings;

use FindBin ();
use lib "$FindBin::Bin/lib";

use Test::Most tests => 10;

use TestApp;
use Dancer::Test;

my $route_doc_class = 'Dancer::Plugin::Documentation::Route';
my $section_doc_class = 'Dancer::Plugin::Documentation::Section';

my $app = 'main';
my @docs = (
	$route_doc_class->new(app => $app, method => 'get',  path => '/',           section => '',     documentation => 'overview'),
	$route_doc_class->new(app => $app, method => 'head', path => '/',           section => '',     documentation => 'overview'),
	$section_doc_class->new(app => $app, section => 'bars', documentation => 'where we drink'),
	$section_doc_class->new(app => $app, section => 'bazs', documentation => 'who knew?'),
	$route_doc_class->new(app => $app, method => 'post', path => '/v1/baz',     section => 'bazs', documentation => 'dunno'),
	$section_doc_class->new(app => $app, section => 'foos', documentation => 'few and fool'),
	$route_doc_class->new(app => $app, method => 'get',  path => '/v1/foo',     section => 'foos', documentation => 'find foo'),
	$route_doc_class->new(app => $app, method => 'head', path => '/v1/foo',     section => 'foos', documentation => 'find foo'),
	$route_doc_class->new(app => $app, method => 'post', path => '/v1/foo',     section => 'foos', documentation => 'create foo'),
	$route_doc_class->new(app => $app, method => 'get',  path => '/v1/foo/:id', section => 'foos', documentation => 'fetch foo'),
	$route_doc_class->new(app => $app, method => 'head', path => '/v1/foo/:id', section => 'foos', documentation => 'fetch foo'),
);

route_exists $_, "$_->[0] $_->[1] is registered properly" for (
	[GET => '/'],
	[POST => '/v1/baz'],
	[GET => '/v1/foo'],
	[HEAD => '/v1/foo'],
	[POST => '/v1/foo'],
	[GET => '/v1/foo/:id'],
);

response_content_is_deeply [GET => '/'], \@docs, 'All the documentation is properly retrieved';
response_content_is_deeply [GET => '/?section=foos'], [@docs[5 .. 10]], 'All section documentation is properly retrieved';
response_content_is_deeply [GET => '/?method=get'], [@docs[0,6,9]], 'All method documentation is properly retrieved';
response_content_is_deeply [GET => '/?path=/v1/foo'], [@docs[6 .. 8]], 'All path documentation is properly retrieved';
