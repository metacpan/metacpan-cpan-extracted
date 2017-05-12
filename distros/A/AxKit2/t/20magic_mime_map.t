#!/usr/bin/perl

use AxKit2::Test tests => 2;

start_server("t/server1",
    [qw(uri_to_file magic_mime_map serve_file)],
);

header_is('/mime/test.xhtml', 'Content-Type', 'text/html',  'known type');
header_is('/mime/test.xxx',   'Content-Type', 'text/plain', 'unknown type');
