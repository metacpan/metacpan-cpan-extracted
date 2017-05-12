# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';
package Apache::Root ;

use Test;
BEGIN { plan tests => 7 } ;
use Apache::ChildExit;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

my $running = 1 ;

ok( 0, Apache::ChildExit::PostponedCount() ) ;
ok( 3, Apache::ChildExit::ENDBlockCount() ) ;


## Comment out this line to force failures
Apache::ChildExit::Postpone ;

ok( 0, Apache::ChildExit::ENDBlockCount() ) ;
ok( 3, Apache::ChildExit::PostponedCount() ) ;

Apache::ChildExit::ChildExit() ;
$running = 0 ;

## Note: First END block is in Test.pm

END {
	$running && $running++ ;
	ok( 3, $running ) ;
	}

END {
	$running && $running++ ;
	ok( 2, $running ) ;
	}
