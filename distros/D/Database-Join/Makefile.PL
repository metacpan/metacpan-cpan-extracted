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
	NAME             => 'Database::Join',
	AUTHOR           => 'Nigel Horne <njh@nigelhorne.com>',
	VERSION_FROM     => 'lib/Database/Join.pm',
	ABSTRACT_FROM    => 'lib/Database/Join.pm',
	LICENSE          => 'gpl_2',
	MIN_PERL_VERSION => '5.010001',
	PREREQ_PM        => {
		'autodie'                  => 0,
		'Carp'                     => 0,
		'Database::Abstraction'    => '0.37',
		'List::Util'               => '1.33',
		'Object::Configure'        => 0,
		'Params::Get'              => '0.13',
		'Params::Validate::Strict' => '0.38',
		'Readonly'                 => '2.00',
		'Scalar::Util'             => 0,
		'Sub::Protected'           => 0,
	}, TEST_REQUIRES => {
		'DBD::CSV'              => 0,
		'DBD::SQLite'           => '1.70',
		'DBI'                   => 0,
		'File::Temp'            => 0,
		'IPC::System::Simple'   => 0,
		'Test::Exception'       => 0,
		'Test::Memory::Cycle'   => 0,
		'Test::Mockingbird'     => '0.13',
		'Test::Most'            => 0,
		'Test::NoWarnings'      => 0,
		'Test::Returns'         => '0.04',
		'Test::Without::Module' => 0,
		'Text::xSV::Slurp'      => 0,
	}, META_MERGE => {
		'meta-spec' => { version => 2 },
		resources   => {
			repository => {
				type => 'git',
				url  => 'https://github.com/nigelhorne/Database-Join.git',
				web  => 'https://github.com/nigelhorne/Database-Join',
			}, bugtracker => {
				web    => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Database-Join',
				url    => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Database-Join',
				mailto => 'bug-Database-Join@rt.cpan.org',
			},
		},
	}, dist => $dist,
	clean => { FILES    => 'Database-Join-*' },
);
