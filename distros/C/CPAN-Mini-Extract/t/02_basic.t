#!/usr/bin/perl

# Basic testing for CPAN::Mini::Extract

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 12;
use File::Spec::Functions ':ALL';
use CPAN::Mini::Extract   ();
use File::Remove          ();

# Prepare the test directories
my $test_remote  = 'http://www.perl.org/CPAN/';
my $test_local   = catdir( 't', 'local'   );
my $test_extract = catdir( 't', 'extract' );





#####################################################################
# Test creation

# Create the most trivial object
SKIP: {
	skip("Skipping network-dependant tests", 5) if LWP::Online::offline();
	clear_test_dirs();
	my $trivial = CPAN::Mini::Extract->new(
		trace          => 0, # Just in case
		remote         => $test_remote,
		local          => $test_local,
		extract        => $test_extract,
		);
	isa_ok( $trivial, 'CPAN::Mini', 'CPAN::Mini::Extract' );
	ok( -d $test_local,   'Constructor creates local dir'      );
	ok( -d $test_extract, 'Constructor creates extraction dir' );
}

# A more complex object
clear_test_dirs();
my $worse = CPAN::Mini::Extract->new(
	trace          => 0, # Just in case
	remote         => $test_remote,
	offline        => 1,
	local          => $test_local,
	extract        => $test_extract,
	extract_force  => 1,
	extract_filter => sub { /\.pm$/ and ! /\b(inc|t)\b/ },
	);
isa_ok( $worse, 'CPAN::Mini', 'CPAN::Mini::Extract' );
ok( -d $test_local,   'Constructor creates local dir'      );
ok( -d $test_extract, 'Constructor creates extraction dir' );



# Clean up
clear_test_dirs();
exit(0);





#####################################################################
# Support Methods

sub clear_test_dirs {
	foreach ( $test_local, $test_extract ) {
		next unless -e $_;
		File::Remove::remove( \1, $_ )
			or die "Failed to remove test directory '$_'";
	}
	ok( ! -e $test_local,   'minicpan local directory does not exist'   );
	ok( ! -e $test_extract, 'minicpan extract directory does not exist' );
}

exit(0);
