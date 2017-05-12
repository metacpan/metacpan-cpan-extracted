#!/usr/bin/env perl -w
# Simple test. Just try to use the module.
use strict;
use warnings;

use Test::More qw( no_plan );
use CGI::Auth::Basic;

ok(1, 'The module loaded ok');
