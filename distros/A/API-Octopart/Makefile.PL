use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
	NAME               => 'API::Octopart',
	AUTHOR             => q{Eric Wheeler <ewheeler@cpan.org>},
	VERSION_FROM       => 'lib/API/Octopart.pm',
	ABSTRACT_FROM      => 'lib/API/Octopart.pm',
	LICENSE            => 'gpl_3',
	MIN_PERL_VERSION   => '5.010',
	CONFIGURE_REQUIRES => {
		'ExtUtils::MakeMaker' => '0',
	},
	META_MERGE => {
		"meta-spec" => { version => 2 },
		resources   => {
			homepage => 'https://github.com/KJ7LNW/perl-API-Octopart',
			bugtracker =>
				{ web => 'https://github.com/KJ7LNW/perl-API-Octopart/issues' },
			repository => {
				url  => 'git@github.com:KJ7LNW/perl-API-Octopart.git',
				type => 'git',
				web  => 'https://github.com/KJ7LNW/perl-API-Octopart.git',
			},

			#x_IRC => 'irc://irc.perl.org/#maybe-someday?',
		},
	},
	TEST_REQUIRES => {
		'Test::More' => '0',
	},
	PREREQ_PM => {
		'LWP::Protocol::https' => '0',
		'Data::Dumper'         => '2.167',
		'Digest::MD5'          => '2.55',
		'JSON'                 => '2.97001',
		'LWP::Protocol::https' => '6.07',
		'LWP::UserAgent'       => '6.34',

	},
	dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
	clean => { FILES    => 'API-Octopart-*' },
);

# Compatibility with old versions of ExtUtils::MakeMaker
unless (eval { ExtUtils::MakeMaker->VERSION('6.64'); 1 }) {
    my $test_requires = delete $WriteMakefileArgs{TEST_REQUIRES} || {};
    @{$WriteMakefileArgs{PREREQ_PM}}{keys %$test_requires} = values %$test_requires;
}

unless (eval { ExtUtils::MakeMaker->VERSION('6.55_03'); 1 }) {
    my $build_requires = delete $WriteMakefileArgs{BUILD_REQUIRES} || {};
    @{$WriteMakefileArgs{PREREQ_PM}}{keys %$build_requires} = values %$build_requires;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
    unless eval { ExtUtils::MakeMaker->VERSION('6.52'); 1 };
delete $WriteMakefileArgs{MIN_PERL_VERSION}
    unless eval { ExtUtils::MakeMaker->VERSION('6.48'); 1 };
delete $WriteMakefileArgs{LICENSE}
    unless eval { ExtUtils::MakeMaker->VERSION('6.31'); 1 };

WriteMakefile(%WriteMakefileArgs);
