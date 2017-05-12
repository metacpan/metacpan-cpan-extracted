use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME          => 'Bryar::DataSource::Multiplex',
	AUTHOR        => 'Ricardo Signes <rjbs@cpan.org>',
	VERSION_FROM  => 'lib/Bryar/DataSource/Multiplex.pm',
	ABSTRACT_FROM => 'lib/Bryar/DataSource/Multiplex.pm',
  LICENSE       => 'perl',
	PL_FILES      => {},
	PREREQ_PM     => {
		'Bryar'      => '2.8_01',
		'Test::More' => 0,
	},
  (eval { ExtUtils::MakeMaker->VERSION(6.46) }
    ? (META_MERGE => {
        resources => {
          Repository => 'http://github.com/rjbs/bryar-datasource-multiplex'
        }
      })
    : ()
  ),
	dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
	clean => { FILES => 'Bryar-DataSource-Multiplex-* cover_db' },
);
