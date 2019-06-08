#!perl -Tw

use strict;
use warnings;
use Test::Most tests => 32;
use Test::NoWarnings;

BEGIN {
	require_ok('CGI::Info');
}

PATHS: {
	delete $ENV{'C_DOCUMENT_ROOT'};
	delete $ENV{'DOCUMENT_ROOT'};

	my $i = new_ok('CGI::Info');
	my $dir = $i->tmpdir();
	ok(-w $dir);
	ok(-d $dir);

	$ENV{'DOCUMENT_ROOT'} = '/non-existant-path';
	$i = new_ok('CGI::Info');
	$dir = $i->tmpdir();
	ok(-w $dir);
	ok(-d $dir);

	$ENV{'C_DOCUMENT_ROOT'} = '/non-existant-path';
	$i = new_ok('CGI::Info');
	$dir = $i->tmpdir();
	ok(-w $dir);
	ok(-d $dir);

	$i = new_ok('CGI::Info');
	$dir = $i->tmpdir(default => '/non-existant-path');
	ok(CGI::Info->tmpdir(default => '/non-existant-path') eq $dir);
	ok($dir eq '/non-existant-path');

	$i = new_ok('CGI::Info');
	$dir = $i->tmpdir({ default => '/non-existant-path' });
	ok($dir eq '/non-existant-path');

	$ENV{'DOCUMENT_ROOT'} = $ENV{'HOME'};
	$i = new_ok('CGI::Info');
	$dir = $i->tmpdir();
	ok(-w $dir);
	ok(-d $dir);

	delete $ENV{'DOCUMENT_ROOT'};

	$ENV{'C_DOCUMENT_ROOT'} = '/non-existant-path';
	$i = new_ok('CGI::Info');
	$dir = $i->tmpdir();
	ok($dir !~ '/non-existant-path');
	ok(-w $dir);
	ok(-d $dir);

	$ENV{'C_DOCUMENT_ROOT'} = $ENV{'HOME'};
	$dir = $i->tmpdir();
	ok(CGI::Info->tmpdir() eq $dir);
	ok($dir !~ '/non-existant-path');
	ok(-w $dir);
	ok(-d $dir);

	$ENV{'C_DOCUMENT_ROOT'} = '/';
	$dir = $i->tmpdir();
	ok(-w $dir);
	ok(-d $dir);

	$dir = CGI::Info::tmpdir();
	ok(defined($dir));
	ok(-w $dir);
	ok(-d $dir);
}
