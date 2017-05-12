use strict;
use warnings;

use Test::More tests => 1;

BEGIN {
	use_ok( 'Catalyst::Plugin::ConfigLoader::Etc' );
}

diag( "Testing Catalyst::Plugin::ConfigLoader::Etc $Catalyst::Plugin::ConfigLoader::Etc::VERSION, Perl $], $^X" );
