use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
	      NAME             => 'DBIx::Fast',
	      AUTHOR           => q{Harun Delgado <hdp@nurmol.com>},
	      ABSTRACT         => 'DBIx::Fast - DBI fast & easy (another one...)',
	      VERSION_FROM     => 'lib/DBIx/Fast.pm',
	      LICENSE          => 'artistic_2',
	      PL_FILES         => {},
	      MIN_PERL_VERSION => 5.008,
	      CONFIGURE_REQUIRES =>
	      {
	       'ExtUtils::MakeMaker' => 0,
	      },
	      BUILD_REQUIRES =>
	      {
	       'Test::More'      => 0,
	       'Test::Exception' => 0.43,
	       'DBD::SQLite'     => 1.50,
	      },
	      PREREQ_PM =>
	      {
	       'Moo'             => 1,
	       'SQL::Abstract'   => 2.00,
	       'DBIx::Connector' => 0.53,
	      },
	      META_MERGE =>
              {
               'meta-spec' => {
			       version => '2',
			       url     => 'http://search.cpan.org/perldoc?CPAN::Meta::Spec',
			      },
	       homepage => '',
	       resources => {
			     repository => {
					    type => 'git',
					    url  => 'git@github.com:SeHarrys/dbix-fast.git',
					    web  => 'https://github.com/SeHarrys/dbix-fast',
					   },
			    },
	      },
	      dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
              clean => { FILES => 'DBIx-Fast-*' },
	     );
