
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'DBIx::BulkUtil',
    VERSION_FROM      => 'lib/DBIx/BulkUtil.pm', # finds $VERSION
    PREREQ_PM         => {
      DBI => 0,
      'Text::CSV_XS' => 0,
      'IPC::Run' => 0,
      Memoize => 0,
      Carp => 0,
      Cwd => 0,
    }, # e.g., Module::Name => 1.1
    EXE_FILES         => ['script/xbcp'],
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/DBIx/BulkUtil.pm', # retrieve abstract from module
       AUTHOR         => 'Douglas Wilson <dougw@cpan.org>') : ()),
);
