#!perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 1;

BEGIN { use_ok( 'Compare::Directory' ) || print "Bail out! "; }

diag( "Testing Compare::Directory $Compare::Directory::VERSION, Perl $], $^X" );
