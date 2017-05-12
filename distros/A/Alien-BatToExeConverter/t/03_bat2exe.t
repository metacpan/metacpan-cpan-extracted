#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More;
BEGIN {
	unless ( $^O eq 'MSWin32' ) {
		plan( skip_all, 'Not on MSWin32' );
		exit(0);
	}
}
plan( tests => 12 );
use File::Spec::Functions    ':ALL';
use File::Remove             ();
use IPC::Run3                ();
use Alien::BatToExeConverter ();

# Prep the file paths
my $bat = catfile( 't', 'data', 'foo.bat' );
my $exe = catfile( 't', 'data', 'foo.exe' );
File::Remove::clear( $exe );
ok(   -f $bat, 'The .bat file exists' );
ok( ! -f $exe, 'The .exe file does not exist' );





#####################################################################
# Generate the Executable in DOS Mode

SCOPE: {
	my $rv = Alien::BatToExeConverter::bat2exe(
		bat => $bat,
		exe => $exe,
		dos => 1,
	);
	ok( $rv, 'bat2exe ok' );
	ok( -f $exe, 'Created exe file' );
}

SCOPE: {
	my $stdin  = '';
	my $stdout = '';
	my $stderr = '';
	my $rv     = IPC::Run3::run3( [ $exe ], \$stdin, \$stdout, \$stderr );
	is( $stdin,  '', 'STDIN ok'  );
	is( $stdout, '', 'STDOUT ok' );
	is( $stderr, '', 'STDERR ok' );
}





#####################################################################
# Repeat with the Window Mode

File::Remove::clear( $exe );

SCOPE: {
	my $rv = Alien::BatToExeConverter::bat2exe(
		bat => $bat,
		exe => $exe,
		dos => 0,
	);
	ok( $rv, 'bat2exe ok' );
	ok( -f $exe, 'Created exe file' );
}

SCOPE: {
	my $stdin  = '';
	my $stdout = '';
	my $stderr = '';
	my $rv     = IPC::Run3::run3( [ $exe ], \$stdin, \$stdout, \$stderr );
	is( $stdin,  '', 'STDIN ok'  );
	is( $stdout, '', 'STDOUT ok' );
	is( $stderr, '', 'STDERR ok' );
}
