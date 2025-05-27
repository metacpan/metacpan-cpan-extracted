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
	NAME => 'Config::Abstraction',
	VERSION_FROM => 'lib/Config/Abstraction.pm', # Path to your module
	AUTHOR	=> 'Nigel Horne <njh@nigelhorne.com>',
	ABSTRACT_FROM	=> 'lib/Config/Abstraction.pm',
	((defined($ExtUtils::MakeMaker::VERSION) && ($ExtUtils::MakeMaker::VERSION >= 6.3002))
		? ('LICENSE'=> 'GPL')
		: ()),
	MIN_PERL_VERSION => '5.10.0',
	PL_FILES => {},
	CONFIGURE_REQUIRES => {
		'ExtUtils::MakeMaker' => 6.64,	# Minimum version for TEST_REQUIRES
	}, PREREQ_PM	=> {
		'Carp' => 0,
		'Config::Auto' => 0,
		'Config::IniFiles' => 0,
		'Data::Reuse' => 0,	# Fails installation tests on recent Perls, RT#100461
		'File::Basename' => 0,
		'File::Slurp' => 0,
		'JSON::MaybeXS'	=> 0,
		'Params::Get' => 0.04,
		'YAML::XS' => 0,
		# 'XML::Parser::Expat' => 0,	# Seems to be needed for Windows
		# 'XML::LibXML' => 0,	# do.
		# 'XML::Simple' => 0,
		'XML::PP' => 0.06,
		'File::Spec' => 0,
		'Hash::Merge'	=> 0,
		'Hash::Flatten'	=> 0,
		'JSON::Parse' => 0
	},
	META_MERGE => {
		'meta-spec' => { version => 2 },
		resources => {
			homepage => 'https://metacpan.org/pod/Config::Abstraction',
			repository => {
				repository => 'https://github.com/nigelhorne/Config-Abstraction',
				type => 'git',
				url => 'git://github.com/nigelhorne/Config-Abstraction.git',
				web => 'https://github.com/nigelhorne/Config-Abstraction'
			}, bugtracker => {
				mailto => 'bug-Config-Abstraction@rt.cpan.org',
				url => 'https://github.com/nigelhorne/Config-Abstraction/issues',
				# web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Config-Abstraction',
				web => 'https://github.com/nigelhorne/Config-Abstraction/issues'
			}
		},
	}, TEST_REQUIRES => {
		'Test::DescribeMe' => 0,
		'Test::Most' => 0,
		'Test::Needs' => 0,
		'Test::TempDir::Tiny' => 0,
		'Test::Without::Module' => 0,
	}, clean => { FILES => 'Config-Abstraction-*' },
	dist => $dist
);
