use 5.005;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Acme::Goedelize',
    VERSION_FROM      => 'lib/Acme/Goedelize.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Acme/Goedelize.pm', # retrieve abstract from module
       AUTHOR         => 'Todor Todorov <acidmax@jambolnet.com>') : ()),
);
