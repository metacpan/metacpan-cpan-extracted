#!/usr/bin/env perl

use strict;
use warnings;

sub cmpv {
	my @v1 = split /\./, shift;
	my @v2 = split /\./, shift;

	while ( @v1 ) {
		return 1 unless @v2;
		my $v1 = shift @v1;
		my $v2 = shift @v2;
		return -1 if $v1 < $v2;
		return 1  if $v1 > $v2;
	}
	return 0 unless @v2 && int join '', @v2;
	1;
}

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
		system 'svn upgrade ' . catfile($Bin,'svn') and die $! if cmpv($ver,1.6) > 0;
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

