#!/usr/bin/env perl

use strict;
use warnings;

BEGIN {
	use File::Copy::Recursive qw'dircopy pathrmdir';
	use File::Spec::Functions qw'catdir catfile';
	use File::Which 'which';
	use FindBin '$Bin';
	use lib catdir $Bin,'git';

	use Test::More;
	if ( which 'git' ) {
		plan tests => 3;
	} else {
		plan skip_all => 'no git executable found';
	}

	pathrmdir catfile $Bin,'git','.git' or die $!;
	dircopy catfile($Bin,'git','dot-git') => catfile($Bin,'git','.git') or die $!;
}

use Catalyst::Test 'TestApp';


is( get('/'), 'ok', 'index' );
is( get('/none'), 'not found', 'nonexistent' );
is( get('/revision'), '9283a3babeb86b6bb23b2091c0f1336d7e7f59d5', 'revision' );

END {
	pathrmdir catfile $Bin,'git','.git' or die $!;
}

