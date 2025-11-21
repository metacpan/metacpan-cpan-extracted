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
	NAME => 'App::Test::Generator',
	VERSION_FROM => 'lib/App/Test/Generator.pm',
	ABSTRACT_FROM => 'lib/App/Test/Generator.pm',
	AUTHOR => 'Nigel Horne <njh@nigelhorne.com>',
	LICENSE => 'GPL',
	EXE_FILES => ['bin/fuzz-harness-generator'],
	MIN_PERL_VERSION => '5.014',
	PREREQ_PM => {
		'autodie' => 0,
		'Carp' => 0,
		'Config::Abstraction' => 0.36,
		'Data::Dumper' => 0,
		'Data::Section::Simple' => 0,
		'File::Spec' => 0,
		'Getopt::Long' => 0,
		'Module::Load::Conditional' => 0,
		'Params::Get' => 0.13,
		'Params::Validate::Strict' => 0.23,
		'Pod::Usage' => 0,
		'Return::Set' => 0.03,
		'Template' => 0,
		'YAML::XS' => 0
	},
	TEST_REQUIRES => {
		'Cwd' => 0,
		'Data::Random' => 0,
		'Data::Random::String' => 0,
		'Data::Random::String::Matches' => 0.02,
		'Data::Random::Structure' => 0,
		'Encode' => 0,
		'File::Temp' => 0,
		'IPC::Run3' => 0,
		'IPC::System::Simple' => 0,
		'JSON::MaybeXS' => 0,
		'Test::DescribeMe' => 0,
		'Test::LectroTest' => 0,
		'Test::Most' => 0,
		'Test::Needs' => 0,
		'Test::Returns' => 0.02
	}, dist => $dist,
	clean	 => { FILES => 'App-Test-Generator-*' },
	META_MERGE => {
		'meta-spec' => { version => 2 },
		resources => {
			homepage => 'https://metacpan.org/pod/App::Test::Generator',
			repository => {
				repository => 'https://github.com/nigelhorne/App-Test-Generator',
				type => 'git',
				url => 'git://github.com/nigelhorne/App-Test-Generator.git',
				web => 'https://github.com/nigelhorne/App-Test-Generator',
				# license => 'http://dev.perl.org/licenses/',
			}, bugtracker => {
				mailto => 'bug-App-Test-Generator@rt.cpan.org',
				web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=App-Test-Generator',
				url => 'https://rt.cpan.org/Public/Dist/Display.html?Name=App-Test-Generator',
				# url => 'https://github.com/nigelhorne/App-Test-Generator/issues',
				# web => 'https://github.com/nigelhorne/App-Test-Generator/issues'
			}
		},
	},
);
