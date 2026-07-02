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
	NAME             => 'App::Project::Doctor',
	AUTHOR           => 'Nigel Horne <njh@nigelhorne.com>',
	VERSION_FROM     => 'lib/App/Project/Doctor.pm',
	ABSTRACT_FROM    => 'lib/App/Project/Doctor.pm',
	LICENSE          => 'gpl_2',
	MIN_PERL_VERSION => '5.016',
	EXE_FILES        => ['script/project-doctor'],
	PREREQ_PM        => {
		'autodie'                   => 0,
		'Carp'                      => 0,
		'CPAN::Meta'                => 0,
		'File::Find'                => 0,
		'File::Spec'                => 0,
		'Getopt::Long'              => '2.50',
		'JSON::MaybeXS'             => 0,
		'Object::Configure' => 0,
		'Params::Get'               => 0,
		'Params::Validate::Strict'          => '0.35',
		'Pod::Checker'              => 0,
		'Pod::Usage'                => 0,
		'Readonly'                  => '2.05',
		'Scalar::Util'              => 0,
		'Term::ANSIColor'           => 0,
		'App::GHGen'                => 0,
		'App::makefilepl2cpanfile'  => 0,
		'App::Test::Generator'      => 0,
		'App::Workflow::Lint'       => 0,
	},
	TEST_REQUIRES => {
		'Test::DescribeMe' => 0,
		'Test::Most'          => 0,
		'Test::Exception'     => 0,
		'Test::Mockingbird'   => 0,
		'Test::Returns'       => 0,
		'Test::Memory::Cycle' => 0,
		'File::Temp'          => 0,
		'File::Path'          => 0,
	},
	META_MERGE => {
		'meta-spec' => { version => 2 },
		resources   => {
			homepage => 'https://metacpan.org/pod/App::Project::Doctor',
			repository => {
				type => 'git',
				url  => 'git://github.com/nigelhorne/App-Project-Doctor.git',
				web  => 'https://github.com/nigelhorne/App-Project-Doctor',
			},
			bugtracker => {
				# web => 'https://github.com/nigelhorne/App-Project-Doctor/issues',
				web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=App-Project-Doctor',
				web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=App-Project-Doctor',
				mailto => 'bug-App-Project-Doctor@rt.cpan.org'
			},
		},
	}, dist => $dist,
	clean => { FILES    => 'App-Project-Doctor-*' },
);
