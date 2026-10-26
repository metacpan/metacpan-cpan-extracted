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
		'JSON::PP'       => 0,
		'List::Util'     => '1.54',
		'Log::Abstraction' => '0.36',	# structured fields
		'Object::Configure' => 0,
		'Params::Get'    => '0.17',
		'Params::Validate::Strict' => '0.41',
		'Readonly'       => '2.05',
		'Scalar::Util'   => 0,
		'Sub::Private'   => '0.07',
		'Sub::Protected' => '0.03',
		'Sys::Hostname'  => 0,
		'Time::HiRes'    => 0,
		'Time::Local'    => 0,
		'version'        => '0.77',
	}, TEST_REQUIRES   => {
		'Errno'          => 0,
		'File::Find'     => 0,
		'File::Temp'     => 0,
		'Test::Exception' => 0,
		'Test::Mockingbird::TimeTravel' => '0.14',
		'Test::Most'     => 0,
	}, META_MERGE      => {
		'meta-spec' => { version => 2 },
		dynamic_config => 0,
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
