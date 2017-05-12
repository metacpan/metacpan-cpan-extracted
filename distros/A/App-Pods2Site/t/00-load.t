use strict;
use warnings;

use Test::More;

plan tests => 11;

BEGIN {
   	use_ok( 'App::Pods2Site' ) || print "Bail out!\n";
	my @mods = qw
					(
						AbstractSiteBuilder
						Args
						Pod2HTML
						PodCopier
						PodFinder
						SiteBuilderFactory
						Util
						SiteBuilder::AbstractBasicFrames
						SiteBuilder::BasicFramesSimpleTOC
						SiteBuilder::BasicFramesTreeTOC
					);
	foreach (@mods)
	{
    	use_ok( "App::Pods2Site::$_" ) || print "Bail out!\n";
	}
}

diag( "Testing App::Pods2Site $App::Pods2Site::VERSION, Perl $], $^X" );
