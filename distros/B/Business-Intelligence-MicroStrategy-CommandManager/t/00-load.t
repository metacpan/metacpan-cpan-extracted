#!perl -T

use Test::More;
use strict;
use warnings;

my $tests;

BEGIN {
   $tests = 1;
   plan tests => $tests;
   chdir 't' if -d 't';
   use lib '../lib';
};


BEGIN {
	use_ok( 'Business::Intelligence::MicroStrategy::CommandManager' );
}

diag( "Testing Business::Intelligence::MicroStrategy::CommandManager $Business::Intelligence::MicroStrategy::CommandManager::VERSION, Perl $], $^X" );
