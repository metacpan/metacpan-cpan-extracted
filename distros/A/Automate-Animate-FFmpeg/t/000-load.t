#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

our $VERSION = '0.13';

plan tests => 1;

BEGIN {
    use_ok( 'Automate::Animate::FFmpeg' ) || print "Bail out!\n";
}

diag( "Testing Automate::Animate::FFmpeg $Automate::Animate::FFmpeg::VERSION, Perl $], $^X" );
