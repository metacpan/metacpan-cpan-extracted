#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 3;
use blib;

BEGIN { use_ok('Blog::BlogML::Reader') };
can_ok('Blog::BlogML::Reader', 'new');
ok(-e 't/example.xml', 'Example blog file exists.');