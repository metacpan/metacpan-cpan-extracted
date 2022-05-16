#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Catalyst::Plugin::SocialMeta' ) || print "Bail out!\n";
}

diag( "Testing Catalyst::Plugin::SocialMeta $Catalyst::Plugin::SocialMeta::VERSION, Perl $], $^X" );
