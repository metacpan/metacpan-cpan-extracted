use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Class::DBI::Plugin::DeepAbstractSearch',
    VERSION_FROM      => 'lib/Class/DBI/Plugin/DeepAbstractSearch.pm',
    PREREQ_PM => {
			Test::More => 0.32,
			Class::DBI => 0.96,
			Class::DBI::Plugin => 0.02,
			SQL::Abstract => 1.18,
    },
   ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Class/DBI/Plugin/DeepAbstractSearch.pm', # retrieve abstract from module
       AUTHOR         => 'Stepan Riha <sriha@cpan.org>') : ()),
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
);
