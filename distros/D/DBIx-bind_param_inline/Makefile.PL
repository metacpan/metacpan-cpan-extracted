use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'DBIx::bind_param_inline',
    VERSION_FROM      => 'lib/DBIx/bind_param_inline.pm', # finds $VERSION
    PREREQ_PM         => {DBI=>1}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/DBIx/bind_param_inline.pm', # retrieve abstract from module
       AUTHOR         => 'David Nicol <davidnico@cpan.org>') : ()),
);
