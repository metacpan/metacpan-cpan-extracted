use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME                => 'Bryar::Config::YAML',
	AUTHOR              => 'Ricardo Signes <rjbs@cpan.org>',
	VERSION_FROM        => 'lib/Bryar/Config/YAML.pm',
	ABSTRACT_FROM       => 'lib/Bryar/Config/YAML.pm',
  LICENSE             => 'perl',
	PL_FILES            => {},
	PREREQ_PM => {
		'Bryar'      => '2.8_01',
    'YAML::Syck' => 0, # min ver unknown
		'Test::More' => 0,
	},
  (eval { ExtUtils::MakeMaker->VERSION(6.46) }
    ? (META_MERGE => {
        resources => {
          Repository => 'http://github.com/rjbs/bryar-config-yaml'
        }
      })
    : ()
  ),
	dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
	clean               => { FILES => 'Bryar-Config-YAML-* cover_db' },
);
