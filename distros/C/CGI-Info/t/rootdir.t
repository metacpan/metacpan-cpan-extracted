#!perl -Tw

use strict;
use warnings;
use Test::Most tests => 29;
use File::Spec;
use Test::NoWarnings;

BEGIN {
	use_ok('CGI::Info');
}

ROOTDIR: {
	delete $ENV{'C_DOCUMENT_ROOT'};
	delete $ENV{'DOCUMENT_ROOT'};

	my $i = new_ok('CGI::Info');
	my $dir = $i->rootdir();
	ok(-r $dir);
	ok(-d $dir);
	if($^O eq 'MSWin32') {
		ok($dir =~ /\\t$/);
	} else {
		ok($dir =~ /\/t$/);
	}

	ok(CGI::Info->rootdir() eq $dir);
	ok(CGI::Info->root_dir() eq $dir);
	ok(CGI::Info::rootdir() eq $dir);
	ok(CGI::Info::root_dir() eq $dir);
	ok(CGI::Info::documentroot() eq $dir);
	ok(CGI::Info::documentroot() eq $dir);

	$ENV{'DOCUMENT_ROOT'} = File::Spec->catdir(File::Spec->tmpdir(), 'xyzzy');
	$dir = CGI::Info->rootdir();
	ok(-r $dir);
	ok(-d $dir);

	delete $ENV{'C_DOCUMENT_ROOT'};
	$ENV{'DOCUMENT_ROOT'} = File::Spec->catdir(File::Spec->tmpdir(), 'xyzzy');
	$i = new_ok('CGI::Info');
	$dir = $i->documentroot();
	ok(-r $dir);
	ok(-d $dir);

	$ENV{'DOCUMENT_ROOT'} = '/';
	$i = new_ok('CGI::Info');
	$dir = $i->root_dir();
	cmp_ok($dir, 'eq', '/', 'Recognises DOCUMENT_ROOT');

	delete $ENV{'DOCUMENT_ROOT'};
	$ENV{'C_DOCUMENT_ROOT'} = File::Spec->catdir(File::Spec->tmpdir(), 'xyzzy');
	$i = new_ok('CGI::Info');
	$dir = $i->rootdir();
	ok(-r $dir);
	ok(-d $dir);

	unless($ENV{'HOME'}) {
		# Most likely this is on Windows
		$ENV{'HOME'} = File::Spec->rootdir();
	}
	delete $ENV{'C_DOCUMENT_ROOT'};
	$ENV{'DOCUMENT_ROOT'} = $ENV{'HOME'};
	$dir = $i->rootdir();
	ok(defined($dir));
	ok($dir eq $ENV{'HOME'});
	ok(-r $dir);
	ok(-d $dir);

	$ENV{'DOCUMENT_ROOT'} = File::Spec->catdir(File::Spec->tmpdir());
	$dir = $i->root_dir();
	ok($dir eq File::Spec->catdir(File::Spec->tmpdir()));
	ok(-r $dir);
	ok(-d $dir);
}
