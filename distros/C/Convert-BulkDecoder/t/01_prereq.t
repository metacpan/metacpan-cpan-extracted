#! perl

use strict;
use warnings;
use Test::More;

my $test;

++$test; use_ok( "MIME::Parser" );
++$test; use_ok( "Digest::MD5" );

done_testing($test);
