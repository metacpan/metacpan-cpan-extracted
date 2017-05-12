use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'AnyEvent::UWSGI',
    VERSION_FROM      => 'lib/AnyEvent/UWSGI.pm', # finds $VERSION
    PREREQ_PM         => {
        common::sense       => 0,
        Errno               => 0,
        AnyEvent            => '5.0',
        AnyEvent::Util      => 0,
        AnyEvent::Handle    => 0,
        Encode              => 0,
        URI::Escape::XS     => 0,
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/AnyEvent/UWSGI.pm', # retrieve abstract from module
       AUTHOR         => 'Alexander Kazakov <voland.kot@gmail.com>') : ()),
    LICENSE           => 'gpl_3',
);
