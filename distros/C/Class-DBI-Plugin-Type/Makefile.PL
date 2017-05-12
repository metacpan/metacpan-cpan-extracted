use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Class::DBI::Plugin::Type',
    VERSION_FROM      => 'Type.pm', # finds $VERSION
    PREREQ_PM         => {
        DBI => "0.94",
        Class::DBI => 0
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'Type.pm', # retrieve abstract from module
       AUTHOR         => 'Simon Cozens <simon@cpan.org>') : ()),
);
