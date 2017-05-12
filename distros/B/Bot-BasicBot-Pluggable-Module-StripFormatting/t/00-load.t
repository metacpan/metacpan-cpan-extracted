#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Bot::BasicBot::Pluggable::Module::StripFormatting' ) || print "Bail out!\n";
}

diag( "Testing Bot::BasicBot::Pluggable::Module::StripFormatting $Bot::BasicBot::Pluggable::Module::StripFormatting::VERSION, Perl $], $^X" );
