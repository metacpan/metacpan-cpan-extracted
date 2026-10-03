use strict;
use warnings;

use ExtUtils::MakeMaker;

my $dist = {
	COMPRESS => 'gzip -9f',	# Compress tarball using gzip
	SUFFIX => 'gz',	# File suffix for tarball
};

if($^O eq 'darwin') {
	$dist->{'TAR'} = 'gtar';
}

WriteMakefile(
	NAME         => 'App::Syslogd',
	VERSION_FROM => 'lib/App/Syslogd.pm',
	ABSTRACT_FROM => 'lib/App/Syslogd.pm',
	AUTHOR       => 'Nigel Horne <njh@nigelhorne.com>',
	# 5.14: the // operator and local $@ that survives croak
	MIN_PERL_VERSION => '5.014',
	# etc/syslogd ships in the tarball but is deliberately NOT in
	# EXE_FILES: "make install" would put it in a bin directory, where a
	# program called syslogd can shadow the system's /usr/sbin/syslogd on
	# PATH.  It is installed by hand into /usr/local/etc; see INSTALLATION.
	EXE_FILES => [],
	PREREQ_PM => {
		'autodie'      => 0,
		'Carp'         => 0,
		'Fcntl'        => 0,
		'FindBin'      => 0,
		'Getopt::Long' => 0,
		'IO::Handle'   => 0,
		'IO::Socket::IP' => 0,
		'IPC::System::Simple' => 0,	# needed by autodie qw(:all)
		'Locale::Maketext' => 0,
		'Object::Configure' => 0.24,
		'Params::Get'  => 0.17,
		'Params::Validate::Strict' => 0.40,
		'parent'       => 0,
		'Readonly'     => 0,
		'Socket'       => 2.000,	# getnameinfo and NIx_NOSERV
		'Sub::Private' => 0.05,	# first version with enforce mode
		'Sub::Protected' => 0.02,
		'Text::CSV'    => 0,
	}, TEST_REQUIRES => {
		'Config'       => 0,
		'Cwd'          => 0,
		'Errno'        => 0,
		'File::Spec'   => 0,
		'IPC::Open3'   => 0,
		'Symbol'       => 0,
		'Time::HiRes'  => 0,
		'File::Temp'   => 0,
		'POSIX'        => 0,
		'Scalar::Util' => 0,
		'Test::DescribeMe' => 0,
		'Test::Memory::Cycle' => 0,
		'Test::Mockingbird' => 0.14,	# mock_scoped multi-method form
		'Test::Most'   => 0,
		'Test::Needs' => 0,
		'Test::Returns' => 0.04,
		'Test::Without::Module' => 0,
		'Text::CSV_PP' => 0,	# t/integration.t compares both backends
		'Test::Warn'   => 0,
	},
	LICENSE => 'gpl_2',
	META_MERGE => {
		'meta-spec' => { version => 2 },
		resources => {
			repository => {
				type => 'git',
				url  => 'https://github.com/nigelhorne/syslogd.git',
				web  => 'https://github.com/nigelhorne/syslogd',
			}, bugtracker => {
				web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=App-Syslogd',
				url => 'https://rt.cpan.org/Public/Dist/Display.html?Name=App-Syslogd',
				mailto => 'bug-App-Syslogd@rt.cpan.org'
			},
		}, prereqs => {
			test => {
				# IP::Country::Fast and CGI::ACL: only for the GeoIP
				# subtests of t/locales.t, which also need the www/
				# tree and so are skipped from CPAN.  CHI: only for the
				# check in t/integration.t that a CHI cache can still be
				# passed in.
				recommends => { 'IP::Country::Fast' => 0, 'CGI::ACL' => 0, 'CHI' => 0 },
			}, develop => {
				# The author tests
				requires => { 'Test::Perl::Critic' => 0, 'Test::Pod' => 0, 'Test::Pod::Coverage' => 0 },
			},
		},
		# Keep the bundled web viewer out of the PAUSE index
		no_index => { directory => ['www'] },
	},
	clean => { FILES => 'App-Syslogd-*' },
	dist => $dist,
);
