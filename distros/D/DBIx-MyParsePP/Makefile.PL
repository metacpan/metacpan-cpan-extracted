use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'DBIx::MyParsePP',
    VERSION_FROM      => 'lib/DBIx/MyParsePP.pm', # finds $VERSION
    PREREQ_PM		  => {
		Parse::Yapp => 0,
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/DBIx/MyParsePP.pm', # retrieve abstract from module
       AUTHOR         => 'Philip Stoev <philip@stoev.org>') : ()),
);
