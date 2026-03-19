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
	NAME		 => 'App::Workflow::Lint',
	ABSTRACT_FROM => 'lib/App/Workflow/Lint.pm',
	VERSION_FROM => 'lib/App/Workflow/Lint.pm',
	AUTHOR	   => 'Nigel Horne (njh@nigelhorne.com)',
	((defined($ExtUtils::MakeMaker::VERSION) && ($ExtUtils::MakeMaker::VERSION >= 6.3002))
		? ('LICENSE'=> 'GPL')
		: ()),
	EXE_FILES    => ['bin/workflow-lint'],
	PREREQ_PM	=> {
		'Exporter' => 0,
		'YAML::PP' => 0,
	}, CONFIGURE_REQUIRES => {
		'ExtUtils::MakeMaker' => 6.64,	# Minimum version for TEST_REQUIRES
	}, TEST_REQUIRES => {
		'Test::DescribeMe' => 0,
		'Test::Most' => 0,
		'Test::Needs' => 0,
	}, dist => $dist,
	clean		=> { FILES => 'App-Workflow-Lint-*' },
	META_MERGE => {	# https://perldoc.perl.org/CPAN::Meta::Spec
		'meta-spec' => { version => 2 },
		resources => {
			homepage => 'https://metacpan.org/pod/App::Workflow::Lint',
			repository => {
				repository => 'https://github.com/nigelhorne/App-Workflow-Lint',
				type => 'git',
				url => 'git://github.com/nigelhorne/App-Workflow-Lint.git',
				web => 'https://github.com/nigelhorne/App-Workflow-Lint',
				# license => 'http://dev.perl.org/licenses/',
			}, bugtracker => {
				web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=App-Workflow-Lint',
				url => 'https://rt.cpan.org/Public/Dist/Display.html?Name=App-Workflow-Lint',
				# web => 'https://github.com/nigelhorne/App-Workflow-Lint/issues',
				# url => 'https://github.com/nigelhorne/App-Workflow-Lint/issues',
				mailto => 'bug-App-Workflow-Lint@rt.cpan.org'
			}
		},
	},
	MIN_PERL_VERSION	=> '5.008'
);
