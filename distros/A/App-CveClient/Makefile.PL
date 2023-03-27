use ExtUtils::MakeMaker;

my %depend = (
	"Getopt::Std"          => 0,
	"JSON::MaybeXS"        => 0,
	"LWP::UserAgent"       => 0,
	"LWP::Protocol::https" => 0,
);

my %meta_merge = (
	'meta-spec'    => {version => 2},
	release_status => 'stable',

	# https://metacpan.org/module/CPAN::Meta::Spec#license
	resources => {
		repository => {
			type => 'git',
			url  => 'https://hacktivis.me/git/cve-client.git/',
			web  => 'https://hacktivis.me/git/cve-client/',
		},
		homepage   => 'https://hacktivis.me/git/cve-client/',
		bugtracker => {
			mailto => 'contact+cve-client@hacktivis.me',
		},
	},
	prereqs => {
		runtime => {
			requires => {%depend},
		},
	},
);

WriteMakefile(
	NAME      => 'App::CveClient',
	ABSTRACT  => 'CLI-based client / toolbox for CVE.org',
	AUTHOR    => 'Haelwenn (lanodan) Monnier <contact+cve-client@hacktivis.me>',
	LICENSE   => 'agpl_3',
	EXE_FILES => ['cve-client'],

	VERSION_FROM  => 'cve-client',
	PREREQ_PM     => \%depend,
	META_MERGE    => \%meta_merge,
	TEST_REQUIRES => {
		'Test::More'   => 0,
		'Test::Output' => 0,
	},
);
