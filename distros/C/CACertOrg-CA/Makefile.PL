use ExtUtils::MakeMaker 6.46;

eval 'use Test::Manifest 1.21';

WriteMakefile(
	NAME          => "CACertOrg::CA",
	VERSION_FROM  => "lib/CACertOrg/CA.pm",
	ABSTRACT_FROM => "lib/CACertOrg/CA.pm",
	AUTHOR        => 'brian d foy <bdfoy@cpan.org>',
	LICENSE       => 'mozilla_1_1 gpl-2 lgpl_2_1',

	'META_MERGE' => {
        'meta-spec' => { version => 2 },
		resources => {
			repository => {
				type => 'git',
				url  => 'git@github.com:briandfoy/cacertorg-ca',
				web  => 'https://github.com/briandfoy/cacertorg-ca',
				},
			},
		},
);
