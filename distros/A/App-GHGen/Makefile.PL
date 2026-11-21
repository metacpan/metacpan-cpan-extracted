use 5.036;
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
	NAME           => 'App::GHGen',
	AUTHOR         => 'Nigel Horne <njh@nigelhorne.com>',
	VERSION_FROM   => 'lib/App/GHGen.pm',
	ABSTRACT_FROM  => 'lib/App/GHGen.pm',
	((defined($ExtUtils::MakeMaker::VERSION) && ($ExtUtils::MakeMaker::VERSION >= 6.3002))
		? ('LICENSE'=> 'gpl_2')
		: ()),
	PREREQ_PM => {
		'YAML::XS' => 0,
		'Path::Tiny' => 0,
		'Term::ANSIColor'=> 0,
		'Getopt::Long' => 0,
		'Readonly' => 0,
	}, TEST_REQUIRES => {
		'Capture::Tiny' => 0,
		'IPC::Run3' => 0,
		'Test::DescribeMe' => 0,
		'Test::Exception' => 0,
		'Test::Mockingbird' => 0,
		'Test::Most' => 0,
		'Test::Returns' => 0.04,
		'Test::Without::Module' => 0,
		'Test::Needs' => 0,
	},
	# EXE_FILES => ['bin/ghgen', 'bin/ghgen-analyze', 'bin/ghgen-generator'],
	EXE_FILES => ['bin/ghgen'],
	dist => $dist,
	clean => { FILES => 'App-GHGen-*' },
	META_MERGE => {	# https://perldoc.perl.org/CPAN::Meta::Spec
		'meta-spec' => { version => 2 },
		provides => {
			map { (my $file = $_) =~ s{^lib/}{};
				(my $module = $file) =~ s{/}{::}g;
				$module =~ s/\.pm\z//;
				$module => { file => $_, version => MM->parse_version($_) } }
				glob('lib/App/GHGen.pm lib/App/GHGen/*.pm')
		},
		resources => {
			homepage => 'https://metacpan.org/pod/App::GHGen',
			repository => {
				repository => 'https://github.com/nigelhorne/App-GHGen',
				type => 'git',
				url => 'git://github.com/nigelhorne/App-GHGen.git',
				web => 'https://github.com/nigelhorne/App-GHGen',
				# license => 'http://dev.perl.org/licenses/',
			}, bugtracker => {
				web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=App-GHGen',
				url => 'https://rt.cpan.org/Public/Dist/Display.html?Name=App-GHGen',
				# web => 'https://github.com/nigelhorne/App-GHGen/issues',
				# url => 'https://github.com/nigelhorne/App-GHGen/issues',
				mailto => 'bug-App-GHGen@rt.cpan.org'
			}
		},
	},
	MIN_PERL_VERSION => '5.036'
);
