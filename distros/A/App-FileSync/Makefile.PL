use strict;
use warnings;
use ExtUtils::MakeMaker;

my $dist = {
	COMPRESS => 'gzip -9f',
	SUFFIX   => 'gz',
};

if ($^O eq 'darwin') {
	$dist->{'TAR'} = 'gtar';
}

WriteMakefile(
    NAME           => 'App::FileSync',
    ABSTRACT_FROM  => 'lib/App/FileSync.pm',
    VERSION_FROM   => 'lib/App/FileSync.pm',
    AUTHOR         => 'Nigel Horne (njh@nigelhorne.com)',
    ((defined($ExtUtils::MakeMaker::VERSION) && ($ExtUtils::MakeMaker::VERSION >= 6.3002))
        ? ('LICENSE' => 'gpl_2')
        : ()),
	EXE_FILES      => [ 'bin/filesync', 'bin/filesync-server', 'bin/filesync-admin' ],
	PREREQ_PM      => {
		'Carp'           => 0,
		'Compress::Raw::Zlib' => 0,
		'Config::Abstraction' => 0,
		'Digest::SHA'    => 0,
		'Encode'         => 0,
		'Exporter'       => 0,
		'Fcntl'          => 0,
		'File::Basename' => 0,
		'File::Copy'     => 0,
		'File::Path'     => 0,
		'File::Spec'     => 0,
		'File::Temp'     => 0,
		'Getopt::Long'   => 0,
		'IO::Handle'     => 0,
		'IPC::Open3'     => 0,
		'JSON::PP'       => 0,
		'Log::Abstraction' => 0,
		'Object::Configure' => 0,
		'POSIX'          => 0,
		'Time::HiRes'    => 0,
		'Time::Local'    => 0,
	}, TEST_REQUIRES  => {
		'File::Temp'     => 0,
		'Test::Deep'     => 0,
		'Test::Exception' => 0,
		'Test::Mockingbird::TimeTravel' => '0.14',
		'Test::Most'     => 0,
	}, META_MERGE     => {
		'meta-spec' => { version => 2 },
		resources   => {
			repository => {
				type => 'git',
				url  => 'https://github.com/nigelhorne/App-FileSync.git',
				web  => 'https://github.com/nigelhorne/App-FileSync',
			},
		},
	    },
	($ExtUtils::MakeMaker::VERSION >= 6.46 ? (META_ADD => { dynamic_config => 0 }) : ()),
);
