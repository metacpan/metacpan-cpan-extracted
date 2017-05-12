# $Revision: 1.1 $
use strict;

use Test::More 'no_plan';

use Business::ISBN qw(:all);

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# parse a bunch of good ones
SKIP:
	{
	my $file = "isbn13s.txt";

	open FILE, $file or 
		skip( "Could not read $file: $!", 1, "Need $file");

	diag "\nChecking ISBN13s... (this may take a bit)\n";
	
	my $bad = 0;
	while( <FILE> )
		{
		chomp;
		my $isbn = Business::ISBN->new( $_ );
		
		my $result = $isbn->is_valid;
		my $text   = $Business::ISBN::ERROR_TEXT{ $result };
		
		$bad++ unless $result eq Business::ISBN::GOOD_ISBN;
		diag "$_ is not valid? [ $result -> $text ]\n" 
			unless $result eq Business::ISBN::GOOD_ISBN;	
		}
	
	close FILE;
	
	ok( $bad == 0, "Match good ISBNs" );
	}