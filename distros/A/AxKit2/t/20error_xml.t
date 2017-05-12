#!/usr/bin/perl

use AxKit2::Test tests => 3;

start_server("t/server1",
    [qw(uri_to_file test/error)],
    ['ErrorStylesheet demo/error.xsl','StackTrace On']
);

content_matches('/', 'The following error occurred: Test Error! at ./plugins/test/error line 18.', 'basic error handling', 1);
content_matches('/', 'Danga::Socket',                                                              'stack trace', 1);

stop_server;

start_server("t/server1",
    [qw(uri_to_file test/error)],
    ['ErrorStylesheet demo/error.xsl','StackTrace Off']
);

content_doesnt_match('/', 'Danga::Socket',                                                         'no stack trace', 1);
