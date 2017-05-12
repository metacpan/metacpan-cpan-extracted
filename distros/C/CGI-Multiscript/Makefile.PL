use 5.008004;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'CGI::Multiscript',
    VERSION_FROM      => 'lib/CGI/Multiscript.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      ( ABSTRACT_FROM  => 'lib/CGI/Multiscript.pm', # retrieve abstract from module
       AUTHOR         => 'Nathan Ross <morgothii@cpan.org>') : ()),
);
