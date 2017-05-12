#!/usr/bin/perl

use AxKit2::Test tests => 11;

start_server("t/server1",[qw(uri_to_file typeless_uri serve_file)],['DirectoryIndex index']);

content_is('/index.html','This is index.html',        'Basic path translation');
content_is('/index','This is index.html',             'Basic typeless operation');
content_is('/','This is index.html',                  'typeless DirectoryIndex');
content_is('/index/foo','This is index.html',         'typeless path_info');

is_redirect('/foo','/foo/',                           'directory redirect');
content_is('/foo','This is foo/index.html',           'directory redirect plus DirectoryIndex');

no_redirect('/multi',                                 'no typeless directory redirect');
content_is('/multi','This is multi.html',             'typeless plus directory');
content_is('/multi/','This is multi/index.html',      'typeless plus DirectoryIndex');

status_is('/index.foo',404,                           'nonexistant file');
status_is('/bar',404,                                 'nonexistant file');
