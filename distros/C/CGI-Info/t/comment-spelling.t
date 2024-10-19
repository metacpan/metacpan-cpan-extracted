#!usr/bin/env perl

use 5.006;
use strict;
use warnings;

use Test::DescribeMe qw(author);
use Test::Most;
use Test::Needs { 'Test::Spelling::Comment' => '0.002' };

Test::Spelling::Comment->import();
Test::Spelling::Comment->new()->add_stopwords(<DATA>)->all_files_ok();

__DATA__
BrowserDetect
cgi
dir
env
ENV
EscapeCage
escapecstring
FBCLID
getpairs
INET
NetBSD
NUL
paramref
params
realpath
rc
Solaris
splitpath
TODO
UA
usr
XSS
