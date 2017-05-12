#!/usr/bin/perl

use strict;
use warnings;

use lib qw( ./lib );

use Test::More tests => 1;

BEGIN { use_ok( 'DateTime::Format::DateParse' ); }
