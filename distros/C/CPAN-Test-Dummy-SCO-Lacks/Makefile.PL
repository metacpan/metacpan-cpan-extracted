use strict;
use warnings;
use ExtUtils::MakeMaker;

my %conf = (
	NAME          => 'CPAN::Test::Dummy::SCO::Lacks',
	AUTHOR        => 'Gabor Szabo <szabgab@cpan.org>',
	VERSION_FROM  => 'lib/CPAN/Test/Dummy/SCO/Lacks.pm',
	ABSTRACT_FROM => 'lib/CPAN/Test/Dummy/SCO/Lacks.pm',
	PREREQ_PM     => {
	},
);

if (eval { ExtUtils::MakeMaker->VERSION(6.46) }) {
	$conf{META_MERGE} = {
		'meta-spec' => { version => 2 },
		resources => {
			repository => {
				type       => 'git',
				url        => 'git://github.com/szabgab/CPAN-Test-Dummy-SCO.git',
				#web        => 'http://github.com/szabgab/CPAN-Test-Dummy-SCO',
				license    => 'http://dev.perl.org/licenses/',
			},
		},
	};
}


WriteMakefile(%conf);

