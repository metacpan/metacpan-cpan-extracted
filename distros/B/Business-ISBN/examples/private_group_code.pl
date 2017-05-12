#!perl
use v5.22;
use feature qw(refaliasing signatures postderef);
no warnings map { "experimental::$_" } qw(refaliasing signatures postderef);

##################################################################
# I added the error_text method in this version. You might have
# to pull from GitHub to use the latest sources.
# https://github.com/briandfoy/business-isbn
use Business::ISBN '2.010_01';

##################################################################
# https://bugs.launchpad.net/evergreen/+bug/1559281/comments/2
#
# This UbuntuOne thread has some example data for a publisher using
# unassigned group codes. It does not note what the publisher code
# ranges should be.
my @tests = (
	[ qw(9786316294241 6316294247) ],  # https://www.worldcat.org/title/black-mass/oclc/933728185
	[ qw(9786316271976 6316271972) ], # DVD "Bridge of Spies" - https://www.worldcat.org/title/bridge-of-spies/oclc/933729520
	[ qw(9786316364036) ], # DVD "Alvin and the Chipmunks. The road chip"  - http://www.btol.com/home_whatshot_details.cfm?sideMenu=Featured%20CDs%20and%20DVDs&home=home_whatshot_details.cfm
	[ qw(9786316334886) ], # DVD "Spectre"
	[ qw(9786316321183) ], # DVD "Southerner"
	[ qw(9786316319401) ], # DVD "Spotlight"
	[ qw(9786316291431) ], # DVD "Steve Jobs"
	);

##################################################################
# This part tries the test cases with the official ISBN data
# These should fail since the publisher is using unassigned group
# codes, which are cleverly created in a way that an invalid
# group code throws off the rest of the parsing.
say "========= Before fake group insertion";
test_isbns( \@tests );

##################################################################
# Now insert the fake group code by playing with the internal data
# structure that you aren't supposed to know about. But, if you want
# to use "bad" data, that's the trade-off
say "========= After fake group insertion";

# the group code is a key in this hash. The first element of the
# array ref is the label for the group code. The second argument is
# another array ref that are the publisher code ranges. To see more,
# look as Business::ISBN::Data's guts. The publisher ranges must be
# strings so items such as "00" are correctly handled as something of
# length 2.
#
# I don't know what Baker and Taylor are claiming to be the publishers.
$Business::ISBN::country_data{ '631' } = [
	'Baker and Taylor',
	[ '0' => '9' ],
	];
test_isbns( \@tests );

##################################################################
# This sub goes through the array of arrays and makes an ISBN
# object out of each thing. It's an array of arrays because I
# kept together the ISBN-10 and ISBN-13 versions.
#
# I use three experimental Perl features here (if I'm going to spend
# the time writing the example for you, I get to choose!), but it's
# not much work to not use them. You get the idea of what this is
# doing.
sub test_isbns ( $tests ) {
	foreach \my @test ( $tests->@* ) {
		foreach my $test_isbn ( @test ) {
			my $isbn = Business::ISBN->new( $test_isbn );
			if( $isbn->is_valid ) {
				say "$test_isbn is valid";
				say "\tgroup     -> ", $isbn->group_code;
				say "\tpublisher -> ", $isbn->publisher_code;
				say "\tarticle   -> ", $isbn->article_code;
				say "\tchecksum  -> ", $isbn->checksum;
				}
			else {
				printf qq(%s is not valid! Error is "%s"\n),
					$test_isbn, $isbn->error_text;
				}
			}
		}
	}

