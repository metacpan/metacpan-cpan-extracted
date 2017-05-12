use 5.00503;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'DBIx::Knowledge',
    VERSION_FROM      => 'lib/DBIx/Knowledge.pm', # finds $VERSION
    PREREQ_PM         => { POSIX => 0, HTML::Entities => 0, CGI::AutoForm => 0, CGI::CRUD => 0, DBI => 0, DBIx::IO, }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/DBIx/Knowledge.pm', # retrieve abstract from module
       AUTHOR         => 'Reed Sandberg') : ()),
);
