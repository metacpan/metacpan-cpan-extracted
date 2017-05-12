#!/usr/bin/perl

use AxKit2::Test;

eval { require IO::AIO; };
if ($@) {
    plan skip_all => 'IO::AIO not present';
} else {
    plan tests => 8;
}

start_server("t/server1",[qw(aio/uri_to_file serve_file)],['DirectoryIndex index.html']);

content_is('/index.html','This is index.html',        'Basic path translation');
content_is('/','This is index.html',                  'DirectoryIndex');
content_is('/index.html/foobar','This is index.html', 'path_info');
is_redirect('/foo','/foo/',                           'directory redirect');

status_is('/index',404,                               'nonexistant file');
status_is('/..',400,                                  'invalid URL');
status_is('/i..ndex',400,                             'better-safe-than-sorry invalid URL');
status_is('/i.%2Endex',400,                           'hidden invalid URL');
