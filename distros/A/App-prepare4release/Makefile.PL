use 5.010;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME             => 'App::prepare4release',
	VERSION_FROM     => 'lib/App/prepare4release.pm',
	ABSTRACT_FROM    => 'lib/App/prepare4release.pm',
	AUTHOR           => 'Sergey Kovalev <skov@cpan.org>',
	LICENSE          => 'perl',
	MIN_PERL_VERSION => '5.010.0',
	PREREQ_PM        => {
		'HTTP::Tiny' => 0.034,
		'JSON::PP'   => 0,
		'Pod::Usage' => 0,
	},
	# t/*.t only; xt/author deps live under META develop (install with
	# cpanm --installdeps . --with-develop for author testing).
	TEST_REQUIRES    => {
		'Test2::Suite' => '0.000139',
	},
	EXE_FILES        => ['bin/prepare4release'],
	META_MERGE       => {
		'meta-spec' => { version => 2 },
		prereqs     => {
			develop => {
				requires => {
					'Devel::Cover'             => 0,
					'Test::DependentModules'   => 0,
					'Module::CPANTS::Analyse'  => 0,
					'Module::CPANTS::Kwalitee' => 0,
					'Test::Compile'            => 0,
					'Test::EOL'                => 0,
					'Test::Kwalitee'           => 0,
					'Test::MinimumVersion'     => 0,
					'Test::PAUSE::Permissions' => 0,
					'Test::Pod'                => 0,
					'Test::Pod::Coverage'      => 0,
					'Test::Portability::Files' => 0,
					'Test::Synopsis'           => 0,
					'Test::Version'            => 0,
				},
			},
		},
		resources => {
			repository => {
				type => 'git',
				url  => 'https://github.com/neo1ite/prepare4release.git',
				web  => 'https://github.com/neo1ite/prepare4release',
			},
			bugtracker => {
				web => 'https://github.com/neo1ite/prepare4release/issues',
			},
		},
	},
);

# BEGIN PREPARE4RELEASE_POSTAMBLE
sub MY::postamble {
  return '' if !-e '.git';
  <<'PREPARE4RELEASE_POD2README';
pure_all :: README.md

README.md : $(VERSION_FROM)
	pod2github $< $@
	$(PERL) maint/inject-readme-badges.pl
PREPARE4RELEASE_POD2README
}
# END PREPARE4RELEASE_POSTAMBLE
