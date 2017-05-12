use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Class::DBI::Plugin::AbstractCount',
    VERSION_FROM      => 'AbstractCount.pm', # finds $VERSION
    PREREQ_PM         =>
			{ 'Class::DBI'         => 0.95
			, 'Class::DBI::Plugin' => 0.02
			, 'SQL::Abstract'      => 1.50
			},
    ($] >= 5.006 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'AbstractCount.pm', # retrieve abstract from module
       AUTHOR         => 'Jean-Christophe Zeus <mail@ljczeus.com>') : ()),
);
