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
		? ('LICENSE'=> 'gpl_2')
		: ()),
	MIN_PERL_VERSION => '5.10.0',
	PL_FILES => {},
	CONFIGURE_REQUIRES => {
		'ExtUtils::MakeMaker' => 6.64,	# Minimum version for TEST_REQUIRES
	}, EXE_FILES => [ 'bin/config-dump' ],
	PREREQ_PM => {
		'Carp' => 0,
		'Config::Auto' => 0,
		'Config::IniFiles' => 0,
		# 'Data::Reuse' => 0,	# Fails installation tests on recent Perls, RT#100461
		'File::Basename' => 0,
		'File::Slurp' => 0,
		'File::Temp' => 0,	# INI parsing of remote config strings
		'Getopt::Long' => 0,
		# JSON::Parse is used first for cheap detection (parse_json returns false on
		# invalid JSON without throwing); JSON::MaybeXS is used for the actual decode.
		# Both are required: Parse avoids noisy CPanel::JSON warnings on bad input.
		'JSON::MaybeXS' => 0,
		'JSON::Parse' => 0,
		'Params::Get' => 0.15,
		'Readonly' => 0,	# used at module load time for AES-256-GCM size constants
		# 'XML::Parser::Expat' => 0,	# Seems to be needed for Windows
		# 'XML::LibXML' => 0,	# do.
		# 'XML::Simple' => 0,
		'XML::PP' => 0.06,
		'File::Spec' => 0,
		'Hash::Merge'	=> 0,
		'Hash::Flatten'	=> '0.05',	# earlier versions mishandle keys containing dots
		'Params::Validate::Strict' => 0.37,
		'Pod::Usage' => 0,
		'Scalar::Util' => 0,
		'TOML::Tiny' => 0,
		'YAML::XS' => '0.80',	# _sanitize_yaml_values guards against !!perl/code in any version
	}, META_MERGE => {
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
				url => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Config-Abstraction',
				web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Config-Abstraction',
				# web => 'https://github.com/nigelhorne/Config-Abstraction/issues'
				# url => 'https://github.com/nigelhorne/Config-Abstraction/issues',
			}
		}, optional_features => {
			encryption => {
				description => 'AES-256-GCM encryption of config values via ENC[] tokens',
				prereqs => { runtime => { requires => { 'CryptX' => 0 } } },
			},
		},
	}, TEST_REQUIRES => {
		'autodie' => 0,
		'File::Glob' => 0,
		'File::stat' => 0,
		'IPC::System::Simple' => 0,	# for scripts/generate_index
		'POSIX' => 0,
		'Test::DescribeMe' => 0,
		'Test::Memory::Cycle' => 0,
		'Test::Mockingbird' => 0.12,
		'Test::Most' => 0,
		'Test::Needs' => 0,
		'Test::Returns' => 0.03,
		'Test::TempDir::Tiny' => 0,
		'Test::Without::Module' => 0,
	}, clean => { FILES => 'Config-Abstraction-*' },
	dist => $dist
);
