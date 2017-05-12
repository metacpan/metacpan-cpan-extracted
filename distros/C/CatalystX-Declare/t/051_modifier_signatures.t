#!/usr/bin/env perl
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use Test::More; 
use Catalyst::Test 'TestApp';

is get('/modsig/foo/2/3'),      'modifiersignatures/foo modified', 'intended arguments work';
is get('/modsig/foo/2'),        'Page Not Found', 'missing argument leads to 404';
is get('/modsig/foo/2/3/4'),    'Page Not Found', 'one argument too many leads to 404';
is get('/modsig/foo/a/b'),      'Page Not Found', 'invalid arguments lead to bad request';


done_testing;
