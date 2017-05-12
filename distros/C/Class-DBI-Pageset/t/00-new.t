#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More tests => 1;

# can we load the library?
BEGIN { use_ok( 'Class::DBI::Pageset' ) };
