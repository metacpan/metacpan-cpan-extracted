#!/usr/bin/perl

# Tests for whether making Archives actually works

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More;
use File::Flat;
use Archive::Builder;

# Create our Generator
use vars qw{$Generator $Section1 $Section2 $files};
sub init {
	$Generator = Archive::Builder->new();
	$Section1 = $Generator->new_section( 'one' );
	$Section1->new_file( 'one', 'string', 'filecontents' );
	my $string = "trivial";
	my $File   = $Section1->new_file( 'two', 'string', \$string );

	# Set the executable flag to ensure modes are written
	$File->executable;

	# Write the test file
	File::Flat->write( 'test.txt', 'test file' );
	$Section1->new_file( 'three', 'file', 'test.txt' );

	# Create a handle to test with
	my $handle = File::Flat->getReadHandle( 'test.txt' );
	$Section1->new_file( 'four', 'handle', $handle );

	# Test the file contents
	$files = {
		'./first/one/one'   => 'filecontents',
		'./first/one/two'   => 'trivial',
		'./first/one/three' => "test file",
		'./first/one/four'  => 'test file',
	};

}
init();


my %archive_types = (
	'tar'    => \&test_tar,
	'tgz'    => \&test_tgz,
	'tar.gz' => \&test_tar_gz,
	'zip'    => \&test_zip,
);

# First, identify the types that we can build
my @types = Archive::Builder::Archive->types;

my $tests = 1;
foreach ( @types ) {
	$tests += 3;
	if ( $archive_types{$_} ) {
		$tests += 7;
	} else {
		diag "No test for type '$_'";
	}
	if ( $_ eq 'tar' ) {
		$tests += 5;
	}
}
foreach my $type (keys %archive_types) {
	diag "Skipping test of '$type' files due to missing dependency" if ! grep {$_ eq $type} @types
}

plan tests => $tests;

ok( scalar @types, 'You can build at least one type of archive' );

# Test the types they have available
foreach ( @types ) {
	test_common( $_ );
	if ( $archive_types{$_} ) {
		$archive_types{$_}->();
	}
	# TODO handle case of invalid type
}






#######################################################################
# Archive type tests

sub test_common {
	my $type = shift;

	# Try to get the new object
	my $Archive = $Generator->archive( $type );
	ok( $Archive, 'Builder->archive returns true' );
	isa_ok( $Archive, 'Archive::Builder::Archive' );
	is( $Archive->type, $type, "Archive->type is $type" );

}

sub test_tar {
	# Get the archive
	my $Archive = $Generator->archive( 'tar' );

	# Get the generated string
	my $scalar = $Archive->generate;

	# Does the string match the expected value
	ok( ref($scalar) eq 'SCALAR', '->generate returns a scalar ref' );
	ok( ($$scalar =~ /trivial/ and $$scalar =~ /filecontents/), 'Tar file appears to contain the correct stuff' );
	ok( length $$scalar > 500, 'Length appears to be great enough' );

	# Save the file
	ok( $Archive->save( 'first' ), '->save returns true' );
	ok( ! -f 'first', '->save DOESNT create the file "first"' );
	ok( -f 'first.tar', "->save does create the file 'first.tar'" );
	file_contains( 'first.tar', $$scalar, '->save seems to save the tar' );

	# Check to see if the executable file was written with the correct mode
	my @list = sort {
		$a->{name} cmp $b->{name}
	} Archive::Tar->list_archive( 'first.tar', 0, [ 'name', 'mode' ] );
	is( scalar(@list), 4, 'Found 4 files in the tarball' );
	is( $list[0]->{name}, 'four', 'Found normal file' );
	is( $list[0]->{mode}, 0644,   'Found normal mode' );
	is( $list[3]->{name}, 'two',  'Found executable file' );
	is( $list[3]->{mode}, 0755,   'Found executable mode' );
}

sub test_tgz {
	# Get the Archive
	my $Archive = $Generator->archive( 'tgz' );

	# Get  the generated string
	my $scalar = $Archive->generate;

	# Does the string match the expected value
	ok( ref($scalar) eq 'SCALAR', '->generate returns a scalar ref' );
	ok( $$scalar =~ /^(?:\037\213|\037\235)/, 'Contents appears to be gzipped' );
	ok( length $$scalar > 160, 'Length appears to be long enough to contain everything' );

	# Save the file
	ok( $Archive->save( 'first' ), '->save returns true' );
	ok( ! -f 'first', '->save DOESNT create the file "first"' );
	ok( -f 'first.tgz', "->save does create the file 'first.tgz'" );
	file_contains( 'first.tgz', $$scalar, '->save seems to save the zipped content' );
}

sub test_tar_gz {
	# Get the Archive
	my $Archive = $Generator->archive( 'tar.gz' );

	# Get  the generated string
	my $scalar = $Archive->generate;

	# Does the string match the expected value
	ok( ref($scalar) eq 'SCALAR', '->generate returns a scalar ref' );
	ok( $$scalar =~ /^(?:\037\213|\037\235)/, 'Contents appears to be gzipped' );
	ok( length $$scalar > 160, 'Length appears to be long enough to contain everything' );

	# Save the file
	ok( $Archive->save( 'first' ), '->save returns true' );
	ok( ! -f 'first', '->save DOESNT create the file "first"' );
	ok( -f 'first.tar.gz', "->save does create the file 'first.tar.gz'" );
	file_contains( 'first.tar.gz', $$scalar, '->save seems to save the zipped content' );
}

sub test_zip {
	# Get the Archive
	my $Archive = $Generator->archive( 'zip' );

	# Get  the generated string
	my $scalar = $Archive->generate;

	# Does the string match the expected value
	ok( ref($scalar) eq 'SCALAR', '->generate returns a scalar ref' );
	ok( $$scalar =~ /^PK/, 'Contents appears to be zipped' );
	ok( length $$scalar > 400, 'Length appears to be long enough to contain everything' );

	# Save the file
	ok( $Archive->save( 'first' ), '->save returns true' );
	ok( ! -f 'first', '->save DOESNT create the file "first"' );
	ok( -f 'first.zip', "->save does create the file 'first.zip'" );
	file_contains( 'first.zip', $$scalar, '->save seems to save the zipped content' );
}


















# Additional tests

sub file_contains {
	my $filename = shift;
	my $contains = shift;
	return ok( undef, "File $filename doesn't exist" ) unless -e $filename;
	return ok( undef, "$filename isn't a file" ) unless -f $filename;
	return ok( undef, "Can't read contents of $filename" ) unless -r $filename;
	my $contents = File::Flat->slurp( $filename )
		or return ok( undef, 'Error while slurping file' );
	return is( $$contents, $contains, "File $filename contents match expected value" );
}




# Clean up
END {
	foreach ( qw{first test.txt first.tar first.tgz first.tar.gz first.zip} ) {
		File::Flat->remove( $_ );
	}
}
