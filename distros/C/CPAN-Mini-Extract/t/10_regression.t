#!/usr/bin/perl

# Regression tests CPAN::Mini::Extract

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 14;
use File::Spec::Functions ':ALL';
use CPAN::Mini::Extract ();
use File::Remove        ();

# Identify the test paths
my $test_remote         = 'http://mirrors.kernel.org/cpan/';
my $test_local          = catdir( 't', 'local'   );
my $test_extract        = catdir( 't', 'extract' );
my $empty_files_archive = catfile( 't', 'data', '10_regression', 'empty_files.tar.gz' );
my $empty_files_dir     = catdir(  't', 'data', '10_regression', 'empty_files' );





#####################################################################
# Test creation

# Create an offline extract object
clear_test_dirs();
my $offline = CPAN::Mini::Extract->new(
	trace          => 0, # Just in case
	offline        => 1,
	remote         => $test_remote,
	local          => $test_local,
	extract        => $test_extract,
	extract_filter => sub { /\.(?:pm|pl|t)$/i },
	);
isa_ok( $offline, 'CPAN::Mini', 'CPAN::Mini::Extract' );
ok( -d $test_local,   'Constructor creates local dir'      );
ok( -d $test_extract, 'Constructor creates extraction dir' );

# Ignoring the actual files in the minicpan, try to extract
# the bad archive directly.
my $rv = $offline->_extract_archive( $empty_files_archive, $empty_files_dir );
ok( $rv, 'Extract test archive OK' );

# Check that files that should exist do
ok( -e $empty_files_dir, 'Output directory exists' );
ok( -e catfile( $empty_files_dir, 'empty_files', 'Good.pm' ), 'Good.pm was extracted' );

# Check that files that shouldn't don't
ok( ! -e catfile( $empty_files_dir, 'empty_files', 'Bad.pm' ), 'Bad.pm does not exist' );
ok( ! -e catfile( $empty_files_dir, 'empty_files', 'dir.pm' ), 'dir.pm does not exist' );

# Clean up
clear_test_dirs();
exit(0);





#####################################################################
# Support Methods

sub clear_test_dirs {
	foreach ( $test_local, $test_extract, $empty_files_dir ) {
		next unless -e $_;
		File::Remove::remove( \1, $_ )
			or die "Failed to remove test directory '$_'";
	}
	ok( ! -e $test_local,      'minicpan local directory does not exist'   );
	ok( ! -e $test_extract,    'minicpan extract directory does not exist' );
	ok( ! -e $empty_files_dir, 'empty_file directory does not exists'      );
}

# And the less testy version for the END
END {
	foreach ( $test_local, $test_extract, $empty_files_dir ) {
		next unless -e $_;
		File::Remove::remove( \1, $_ );
	}		
}
