#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More;
use URI::file             ();
use File::Spec::Functions ':ALL';
use File::Remove          'clear';
use CPANDB::Generator     ();
BEGIN {
	unless ( $ENV{ADAMK_CHECKOUT} ) {
		plan( skip_all => 'Only run by the author' );
	}
	unless ( $^O eq 'MSWin32' ) {
		plan( skip_all => 'Only runs on Win32' );
	}
}

# Try to find a minicpan
my @minicpan = grep { -d $_ } map { "$_:\\minicpan" } reverse ( 'A' .. 'G' );
unless ( @minicpan ) {
	die("Failed to find a minicpan to test with");
}

# We can (finally) be sure that we can run the test
plan( tests => 10 );

# Define the archives we'll be making
my @archives = qw{
	cpandb.gz
	cpandb.bz2
	cpandb.lz
};
clear( @archives );
foreach my $file ( @archives ) {
	ok( ! -f $file, "File '$file' does not exist" );
}

# Where should we generate the sqlite database
my $sqlite = catfile( 't', 'sqlite.db' );
clear( $sqlite );
ok( ! -f $sqlite, "Database '$sqlite' does not exist" );





######################################################################
# Main Tests

# Create the generator
my $url    = URI::file->new($minicpan[0])->as_string;
my $cpandb = new_ok( 'CPANDB::Generator' => [
        urllist => [ "$url/" ],
	sqlite  => $sqlite,
	trace   => 0,
] );
clear($cpandb->sqlite);

# Generate the database
ok( $cpandb->run, '->run' );

# Validate the result
ok( -f $sqlite, "Created database '$sqlite'" );
foreach my $file ( qw{
	cpandb.gz
	cpandb.bz2
	cpandb.lz
} ) {
	ok( -f $file, "File '$file' exists" );
}
