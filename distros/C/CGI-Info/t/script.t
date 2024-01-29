#!perl -Tw

use strict;
use warnings;
use Test::Most tests => 64;
use File::Spec;
use Cwd;
use Test::NoWarnings;
use Tie::Filehandle::Preempt::Stdin;

BEGIN {
	use_ok('CGI::Info');
}

PATHS: {
        delete $ENV{'SCRIPT_NAME'};
	delete $ENV{'DOCUMENT_ROOT'};
        delete $ENV{'SCRIPT_FILENAME'};

	my $i = new_ok('CGI::Info');
	ok(File::Spec->file_name_is_absolute($i->script_path()));
	ok($i->script_path() =~ /.+script\.t$/);
	ok($i->script_name() eq 'script.t');
	ok($i->script_path() eq File::Spec->catfile($i->script_dir(), $i->script_name()));
	ok($i->script_path() eq File::Spec->catfile(CGI::Info::script_dir(), $i->script_name()));
	# Check calling twice return path
	ok($i->script_name() eq 'script.t');

	ok(-f $i->script_path());
	my @statb = stat($i->script_path());
	ok(defined($statb[9]));

	# Test full path given as the name of the script
	$ENV{'SCRIPT_NAME'} = $i->script_path();
	$i = new_ok('CGI::Info');
	ok(File::Spec->file_name_is_absolute($i->script_path()));
	ok($i->script_path() =~ /.+script\.t$/);
	if($^O eq 'MSWin32') {
		TODO: {
			local $TODO = 'Absolute path test needs to be done on Windows';
			ok($i->script_name() eq 'script.t');
		}
	} else {
		ok($i->script_name() eq 'script.t');
	}

	$ENV{'SCRIPT_NAME'} = '/cgi-bin/foo.pl';
	if($^O eq 'MSWin32') {
		$ENV{'DOCUMENT_ROOT'} = '\var\www\bandsman';
		$ENV{'SCRIPT_FILENAME'} = '\var\www\bandsman\cgi-bin\foo.pl';
	} else {
		$ENV{'DOCUMENT_ROOT'} = '/var/www/bandsman';
		$ENV{'SCRIPT_FILENAME'} = '/var/www/bandsman/cgi-bin/foo.pl';
	}
	$i = new_ok('CGI::Info');
	if($^O eq 'MSWin32') {
		ok($i->script_dir() eq '\var\www\bandsman\cgi-bin');
		ok($i->script_path() eq '\var\www\bandsman\cgi-bin\foo.pl');
	} else {
		ok($i->script_dir() eq '/var/www/bandsman/cgi-bin');
		ok($i->script_path() eq '/var/www/bandsman/cgi-bin/foo.pl');
	}
	ok($i->script_name() eq 'foo.pl');

	# The name is cached - check reading it twice returns the same value
	ok($i->script_name() eq 'foo.pl');
	if($^O eq 'MSWin32') {
		ok($i->script_path() eq '\var\www\bandsman\cgi-bin\foo.pl');
		ok($i->script_dir() eq '\var\www\bandsman\cgi-bin');
	} else {
		ok($i->script_path() eq '/var/www/bandsman/cgi-bin/foo.pl');
		ok($i->script_dir() eq '/var/www/bandsman/cgi-bin');
	}

	$ENV{'DOCUMENT_ROOT'} = '/path/to';
	$ENV{'SCRIPT_NAME'} = '/cgi-bin/bar.pl';
        delete $ENV{'SCRIPT_FILENAME'};

	$i = new_ok('CGI::Info');
	ok($i->script_name() eq 'bar.pl');
	if($^O eq 'MSWin32') {
		TODO: {
			local $TODO = 'Absolute path test needs to be done on Windows';
			ok($i->script_path() eq '/path/to/cgi-bin/bar.pl');
		}
	} else {
		ok($i->script_path() eq '/path/to/cgi-bin/bar.pl');
	}

        delete $ENV{'DOCUMENT_ROOT'};
	$ENV{'SCRIPT_NAME'} = '/cgi-bin/bar.pl';
        delete $ENV{'SCRIPT_FILENAME'};

	$i = new_ok('CGI::Info');
	ok($i->script_name() eq 'bar.pl');
	ok($i->script_path() eq File::Spec->catfile(Cwd::abs_path(), 'cgi-bin/bar.pl'));
	if($^O eq 'MSWin32') {
		TODO: {
			local $TODO = 'Script_dir test needs to be done on Windows';
			ok($i->script_dir() eq Cwd::abs_path());
		}
	} else {
		ok($i->script_dir() eq File::Spec->catfile(Cwd::abs_path(), 'cgi-bin'));
	}

	$ENV{'SCRIPT_NAME'} = 'cgi-bin/bar.pl';
	$ENV{'DOCUMENT_ROOT'} = '/tmp';
	$i = new_ok('CGI::Info');
	ok($i->script_name() eq 'bar.pl');
	ok($i->script_path() eq File::Spec->catfile('/tmp', 'cgi-bin/bar.pl'));
	if($^O eq 'MSWin32') {
		TODO: {
			local $TODO = 'Script_dir test needs to be done on Windows';
			ok($i->script_dir() eq File::Spec->catfile('/tmp', 'cgi-bin'));
		}
	} else {
		ok($i->script_dir() eq File::Spec->catfile('/tmp', 'cgi-bin'));
	}

	$ENV{'SCRIPT_NAME'} = '/cgi-bin/bar.pl';
	$i = new_ok('CGI::Info');
	ok($i->script_name() eq 'bar.pl');
	ok($i->script_path() eq File::Spec->catfile('/tmp', 'cgi-bin/bar.pl'));
	if($^O eq 'MSWin32') {
		TODO: {
			local $TODO = 'Script_dir test needs to be done on Windows';
			ok($i->script_dir() eq File::Spec->catfile('/tmp', 'cgi-bin'));
		}
	} else {
		ok($i->script_dir() eq File::Spec->catfile('/tmp', 'cgi-bin'));
	}

	$ENV{'SCRIPT_NAME'} = '/tmp/cgi-bin/bar.pl';
	delete $ENV{'DOCUMENT_ROOT'};
	$i = new_ok('CGI::Info');
	ok($i->script_name() eq 'bar.pl');
	if($^O eq 'MSWin32') {
		TODO: {
			local $TODO = 'Script_dir test needs to be done on Windows';
			ok($i->script_dir() =~ /\/tmp\/cgi-bin$/);
			ok($i->script_path() =~ /\/tmp\/cgi-bin\/bar.pl$/);
		}
	} else {
		ok($i->script_dir() =~ /\/tmp\/cgi-bin$/);
		ok($i->script_path() =~ /\/tmp\/cgi-bin\/bar.pl$/);
	}

	# No leading /
	$ENV{'SCRIPT_NAME'} = 'tmp/cgi-bin/bar.pl';
	$i = new_ok('CGI::Info');
	ok($i->script_name() eq 'bar.pl');
	if($^O eq 'MSWin32') {
		TODO: {
			local $TODO = 'Script_dir test needs to be done on Windows';
			ok($i->script_dir() =~ /\/tmp\/cgi-bin$/);
			ok($i->script_path() =~ /\/tmp\/cgi-bin\/bar.pl$/);
		}
	} else {
		ok($i->script_dir() =~ /\/tmp\/cgi-bin$/);
		ok($i->script_path() =~ /\/tmp\/cgi-bin\/bar.pl$/);
	}

	$ENV{'SCRIPT_NAME'} = '/cgi-bin/bar.pl';
	$ENV{'DOCUMENT_ROOT'} = '/tmp';
	$i = new_ok('CGI::Info');
	ok($i->script_name() eq 'bar.pl');
	if($^O eq 'MSWin32') {
		TODO: {
			local $TODO = 'Script_dir test needs to be done on Windows';
			ok($i->script_dir() =~ /\/tmp\/cgi-bin$/);
			ok($i->script_path() =~ /\/tmp\/cgi-bin\/bar.pl$/);
		}
	} else {
		ok($i->script_dir() =~ /\/tmp\/cgi-bin$/);
		ok($i->script_path() =~ /\/tmp\/cgi-bin\/bar.pl$/);
	}

	$ENV{'SCRIPT_NAME'} = 'bar.pl';
	$ENV{'DOCUMENT_ROOT'} = '/tmp';
	$i = new_ok('CGI::Info');
	ok($i->script_name() eq 'bar.pl');
	if($^O eq 'MSWin32') {
		TODO: {
			local $TODO = 'Script_dir test needs to be done on Windows';
			ok($i->script_dir() eq '\\tmp');
			ok($i->script_path() eq '\\tmp\\bar.pl');
		}
	} else {
		ok($i->script_dir() eq '/tmp');
		ok($i->script_path() eq '/tmp/bar.pl');
	}

	delete $ENV{'DOCUMENT_ROOT'};
	$i = new_ok('CGI::Info');
	ok($i->script_name() eq 'bar.pl');
	if($^O eq 'MSWin32') {
		TODO: {
			local $TODO = 'Script_dir test needs to be done on Windows';
			ok($i->script_dir() =~ /\\CGI-Info$/i);
			ok($i->script_path() =~ /\\.+bar\.pl$/);
		}
	} else {
		ok($i->script_dir() =~ /\/CGI-Info/i);
		ok($i->script_path() =~ /\/.+bar\.pl$/);
	}

	my $object = tie *STDIN,
		'Tie::Filehandle::Preempt::Stdin',
		("fred=wilma\n", "quit\n");
	$i = new_ok('CGI::Info');
	my %p = %{$i->params()};
	ok($p{fred} eq 'wilma');
	ok(!defined($p{barney}));
	ok($i->fred() eq 'wilma');
	ok(!defined($i->barney()));

	$ENV{'SCRIPT_FILENAME'} = '/tulip';
	delete $ENV{'SCRIPT_NAME'};
	delete $ENV{'DOCUMENT_ROOT'};
	$i = new_ok('CGI::Info');
	cmp_ok($i->script_path(), 'eq', '/tulip', 'SCRIPT_FILENAME is read from the environment');
}
