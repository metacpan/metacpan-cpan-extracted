#!perl -T

use strict;
use warnings;

use Test::More tests => 1;

use_ok( '[% module %]' );

diag( "Testing [% module %] $[% module %]::VERSION, Perl $], $^X" );
