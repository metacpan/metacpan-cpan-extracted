#!/usr/bin/perl

use AxKit2::Test tests => 3;

start_server("t/server1",
    [qw(uri_to_file fast_mime_map serve_file)],
    ['MimeMap .bar text/x-bar','MimeMap .foo text/x-foo']
);

header_is('/mime/test.xhtml', 'Content-Type', 'application/xhtml+xml',  'predefined types');
header_is('/mime/test.foo',   'Content-Type', 'text/x-foo',             'user defined types');
header_is('/mime/test.xxx',   'Content-Type', 'text/html',              'unknown type');
