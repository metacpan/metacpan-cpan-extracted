use strict;
use warnings;
use ExtUtils::MakeMaker;

my $dist = {
	COMPRESS => 'gzip -9f',
	SUFFIX   => 'gz',
};

if ($^O eq 'darwin') {
	$dist->{'TAR'} = 'gtar';
}

WriteMakefile(
	NAME          => 'Class::Abstract',
	AUTHOR        => q{Nigel Horne <njh@nigelhorne.com>},
	VERSION_FROM  => 'lib/Class/Abstract.pm',
	ABSTRACT_FROM => 'lib/Class/Abstract.pm',
	((defined($ExtUtils::MakeMaker::VERSION) &&
	  ($ExtUtils::MakeMaker::VERSION >= 6.3002))
		? ('LICENSE' => 'gpl') : ()),
	PREREQ_PM => {
		'Carp'       => 0,
		'Readonly'   => 0,
		'Return::Set' => 0,
		'Scalar::Util' => 0,
	},
	TEST_REQUIRES => {
		'Test::Memory::Cycle' => 0,
		'Test::Mockingbird' => 0,
		'Test::Most'  => 0,
		'Test::Returns' => 0,
	},
	clean   => { FILES => 'Class-Abstract-*' },
	dist    => $dist,
	META_MERGE => {
		'meta-spec' => { version => 2 },
		resources => {
			homepage   => 'https://metacpan.org/pod/Class::Abstract',
			repository => {
				type => 'git',
				url  => 'git://github.com/nigelhorne/Class-Abstract.git',
				web  => 'https://github.com/nigelhorne/Class-Abstract',
			},
			bugtracker => {
				web    => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Class-Abstract',
				url    => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Class-Abstract',
				mailto => 'bug-Class-Abstract@rt.cpan.org',
			},
		},
	},
	MIN_PERL_VERSION => '5.008',
);
