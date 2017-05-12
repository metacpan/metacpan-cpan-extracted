#!/usr/bin/env perl

use strict;
use warnings;

BEGIN {
	use File::Copy::Recursive qw'dircopy pathrmdir';
	use File::Spec::Functions qw'catdir catfile';
	use File::Which 'which';
	use FindBin '$Bin';
	use lib catdir $Bin,'hg';

	use Test::More;
	if ( which 'hg' ) {
		plan tests => 3;
	} else {
		plan skip_all => 'no hg executable found';
	}

	pathrmdir catfile $Bin,'hg','.hg' or die $!;
	dircopy catfile($Bin,'hg','dot-hg') => catfile($Bin,'hg','.hg') or die $!;
}

use Catalyst::Test 'TestApp';


is( get('/'), 'ok', 'index' );
is( get('/none'), 'not found', 'nonexistent' );
is( get('/revision'), 'ce0f99fa3554', 'revision' );

END {
	pathrmdir catfile $Bin,'hg','.hg' or die $!;
}

