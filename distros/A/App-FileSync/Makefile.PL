#!/usr/bin/env perl

use strict;
use warnings;
use ExtUtils::MakeMaker 6.64;

my $dist = {
	COMPRESS => 'gzip -9f',	# Compress tarball using gzip
	SUFFIX => 'gz',	# File suffix for tarball
};

if ($^O eq 'darwin') {
	$dist->{'TAR'} = 'gtar';
}

# Process keeps a child from inheriting the parent's pipe ends on Windows.
# Win32API::File is core there (since 5.8.9) and cannot be built anywhere
# else, so it is declared only when Makefile.PL runs on Windows.  It is kept
# out of the PREREQ_PM literal on purpose: makefilepl2cpanfile reads that
# block without running it, and would make it a requirement everywhere,
# which fails "cpanm --installdeps ." on Linux and macOS.
my %windows_only = $^O eq 'MSWin32' ? ('Win32API::File' => 0) : ();

WriteMakefile(
	NAME               => 'App::FileSync',
	ABSTRACT_FROM      => 'lib/App/FileSync.pm',
	VERSION_FROM       => 'lib/App/FileSync.pm',
	AUTHOR             => 'Nigel Horne (njh@nigelhorne.com)',
	LICENSE            => 'gpl_2',
	MIN_PERL_VERSION   => '5.014',	# s///r
	EXE_FILES          => [ 'bin/filesync', 'bin/filesync-server', 'bin/filesync-admin' ],
	clean		=> { FILES => 'App-FileSync-*' },
	dist               => $dist,
	CONFIGURE_REQUIRES => {
		'ExtUtils::MakeMaker' => '6.64',	# first to honour TEST_REQUIRES
	}, PREREQ_PM       => {
		'autodie'        => '2.37',
		'Carp'           => 0,
		'Compress::Raw::Zlib' => 0,
		'Config::Abstraction' => '0.41',	# explain_sources()
		'Cwd'            => 0,
		'Digest::SHA'    => 0,
		'Exporter'       => 0,
		'Fcntl'          => 0,
		'File::Basename' => 0,
		'File::Copy'     => 0,
		'File::Path'     => 0,
		'File::Spec'     => 0,
		'File::Temp'     => 0,
		'FindBin'        => 0,
		'Getopt::Long'   => 0,
		'IO::Handle'     => 0,
		'IPC::Open3'     => 0,
		'IPC::System::Simple' => '1.30',
		'JSON::MaybeXS'  => '1.004',	# pulls in Cpanel::JSON::XS given a compiler
		'JSON::PP'       => 0,
		'List::Util'     => '1.54',
		'Log::Abstraction' => '0.36',	# structured fields
		'Object::Configure' => 0,
		'Params::Get'    => '0.17',
		'Params::Validate::Strict' => '0.41',
		'POSIX'          => 0,
		'Readonly'       => '2.05',
		'Scalar::Util'   => 0,
		'Sub::Private'   => '0.07',
		'Sub::Protected' => '0.03',
		'Sys::Hostname'  => 0,
		'Time::HiRes'    => 0,
		'Time::Local'    => 0,
		'version'        => '0.77',
		%windows_only,
	}, TEST_REQUIRES   => {
		'Errno'          => 0,
		'File::Find'     => 0,
		'File::Temp'     => 0,
		'Test::Exception' => 0,
		'Test::Mockingbird::TimeTravel' => '0.14',
		'Test::Most'     => 0,
		'Test::Permissions' => 0,
		'Tie::Hash'      => 0,
	}, META_MERGE      => {
		'meta-spec' => { version => 2 },
		prereqs     => {
			runtime => {
				recommends => {
					'Cpanel::JSON::XS' => 0,	# JSON::MaybeXS adds it given a compiler
				},
			},
		},
		# 1: the prerequisites depend on the platform (%windows_only), so
		# an installer must run Makefile.PL rather than trust META.json.
		dynamic_config => 1,
		no_index    => {
			directory => [ 't', 'xt' ],	# t/lib/TestSync.pm is not for CPAN
		},
		resources   => {
			repository => {
				type => 'git',
				url  => 'https://github.com/nigelhorne/App-FileSync.git',
				web  => 'https://github.com/nigelhorne/App-FileSync',
			},
			bugtracker => {
				web => 'https://github.com/nigelhorne/App-FileSync/issues',
			},
		},
	},
);
