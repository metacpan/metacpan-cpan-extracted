use ExtUtils::MakeMaker;

my $dist = {
	COMPRESS => 'gzip -9f',	# Compress tarball using gzip
	SUFFIX => 'gz',	# File suffix for tarball
};

if($^O eq 'darwin') {
	$dist->{'TAR'} = 'gtar';
}

WriteMakefile(
	NAME          => 'App::WebPerimeterScan',
	VERSION_FROM  => 'lib/App/WebPerimeterScan.pm',
	MIN_PERL_VERSION => '5.026',
	LICENSE       => 'gpl_2',
	EXE_FILES     => ['bin/webperimeter'],
	CONFIGURE_REQUIRES => {
		# TEST_REQUIRES is ignored before 6.64; every supported Perl ships a newer one.
		'ExtUtils::MakeMaker' => 6.64,
	}, PREREQ_PM    => {
		'Carp'                   => 0,
		'Cwd'                    => 0,
		'Data::Validate::IP'     => 0.31,
		'Digest::MD5'            => 0,
		'Encode'                 => 0,
		'Errno'                  => 0,
		'Fcntl'                  => 0,
		'File::Find'             => 0,
		'File::Spec'             => 0,
		'FindBin'                => 0,	# bin/webperimeter
		'Getopt::Long'           => 2.50,
		'HTML::Parser'           => 3.71,	# also provides HTML::Entities
		'HTML::SimpleLinkExtor'  => 1.20,
		'IPC::System::Simple'    => 1.30,	# autodie :all needs it for system()
		'IO::Select'             => 1.17,
		'IO::Socket::INET'       => 1.31,
		'IO::Socket::SSL'        => 2.000,
		'JSON::PP'               => 4.00,
		'Net::SSLeay'            => 1.92,
		'Object::Configure' => 0.24,
		'Params::Get'            => 0.17,
		'Params::Validate::Strict' => 0.41,
		'POSIX'                  => 0,
		'Readonly'               => 2.05,
		'Scalar::Util'           => 0,
		'Socket'                 => 2.020,
		'Sub::Private'           => 0.09,
		'Sub::Protected'         => 0.03,
		'Term::ANSIColor'        => 0,
		'Time::HiRes'            => 1.97,
		'Time::Local'            => 1.28,
		'URI'                    => 1.70,
		'autodie'                => 2.37,
		'parent'                 => 0,
		'version'                => 0.77,	# version->declare
	}, TEST_REQUIRES => {
		'File::Temp' => 0,
		'Test::DescribeMe' => 0,
		'Test::Fatal' => 0,
		'Test::Most' => 0,
	},
	ABSTRACT_FROM	=> 'lib/App/WebPerimeterScan.pm',
	AUTHOR        => 'Nigel Horne <njh@nigelhorne.com>',
	dist => $dist,
	clean	=> { FILES => 'App-WebPerimeterScan-*' },
	META_MERGE => {
		'meta-spec' => { version => 2 },
		resources => {
			repository => {
				type => 'git',
				url  => 'git://github.com/nigelhorne/App-WebPerimeterScan.git',
				web  => 'https://github.com/nigelhorne/App-WebPerimeterScan',
			},
			bugtracker => {
				web => 'https://github.com/nigelhorne/App-WebPerimeterScan/issues',
			},
		},
	},
);
