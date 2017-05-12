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
		my $dir = $ver < 1.7 ? 1.6: 1.7;
		pathrmdir catfile $Bin,'svn','.svn';
		dircopy catfile($Bin,'svn',"dot-svn-$dir") => catfile($Bin,'svn','.svn') or die $!;
	} else {
		plan skip_all => 'no svn executable found';
	}
}

use Catalyst::Test 'TestApp';


is( get('/'), 'ok', 'index' );
is( get('/none'), 'not found', 'nonexistent' );
is( get('/revision'), '5', 'revision' );

END {
	pathrmdir catfile $Bin,'svn','.svn' or die $!;
}

