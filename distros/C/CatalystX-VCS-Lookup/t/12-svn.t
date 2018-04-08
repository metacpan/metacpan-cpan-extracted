#!/usr/bin/env perl

use strict;
use warnings;

BEGIN {
	use File::Copy::Recursive qw'dircopy pathrmdir';
	use File::Spec::Functions qw'catdir catfile';
	use File::Which 'which';
	use FindBin '$Bin';
	use lib catdir $Bin,'svn';

	use Test::More;
	if ( which 'svn' ) {
		plan tests => 3;
		my ($line) = `svn --version`;
		diag $line;
		my ($ver) = $line =~ /\bversion\s+(\d+\.\d+)/i;
		pathrmdir catfile $Bin,'svn','.svn';
		dircopy catfile($Bin,'svn',"dot-svn") => catfile($Bin,'svn','.svn') or die $!;
		system 'svn upgrade ' . catfile($Bin,'svn') and die $! if $ver>1.6;
	} else {
		plan skip_all => 'no svn executable found';
	}
}

use Catalyst::Test 'TestApp';


is( get('/'), 'ok', 'index' );
is( get('/none'), 'not found', 'nonexistent' );
is( get('/revision'), '2', 'revision' );

END {
	pathrmdir catfile $Bin,'svn','.svn' or die $!;
}

