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
    NAME             => 'App::GHGen',
    AUTHOR           => 'Nigel Horne <njh@nigelhorne.com>',
    VERSION_FROM     => 'lib/App/GHGen.pm',
    ABSTRACT_FROM    => 'lib/App/GHGen.pm',
	((defined($ExtUtils::MakeMaker::VERSION) && ($ExtUtils::MakeMaker::VERSION >= 6.3002))
		? ('LICENSE'=> 'GPL')
		: ()),
    MIN_PERL_VERSION => '5.036',

    PREREQ_PM => {
        'YAML::XS'         => 0,
        'Path::Tiny'       => 0,
        'Term::ANSIColor'  => 0,
        'Getopt::Long'     => 0,
    }, TEST_REQUIRES => {
        'Test::More'      => '0.98',
	'Test::DescribeMe' => 0,
        'Test::Exception' => 0,
    },

	# EXE_FILES => ['bin/ghgen', 'bin/ghgen-analyze', 'bin/ghgen-generator'],
	EXE_FILES => ['bin/ghgen'],

	dist  => $dist,
	clean => { FILES => 'App-GHGen-*' },
	META_MERGE => {	# https://perldoc.perl.org/CPAN::Meta::Spec
		'meta-spec' => { version => 2 },
		resources => {
			homepage => 'https://metacpan.org/pod/App::GHGen',
			repository => {
				repository => 'https://github.com/nigelhorne/App-GHGen',
				type => 'git',
				url => 'git://github.com/nigelhorne/App-GHGen.git',
				web => 'https://github.com/nigelhorne/App-GHGen',
				# license    => 'http://dev.perl.org/licenses/',
			}, bugtracker => {
				mailto => 'bug-App-GHGen@rt.cpan.org',
				url => 'https://github.com/nigelhorne/App-GHGen/issues',
				# web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=App-GHGen',
				web => 'https://github.com/nigelhorne/App-GHGen/issues'
			}
		},
	},
);
