use 5.005000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'AnyEvent::HTTP::Socks',
    VERSION_FROM      => 'lib/AnyEvent/HTTP/Socks.pm', # finds $VERSION
    LICENSE           => 'perl',
    PREREQ_PM         => { 'IO::Socket::Socks' => 0.66, 'AnyEvent::HTTP' => 1.5 }, # e.g., Module::Name => 1.1
    BUILD_REQUIRES    => { 'Test::More' => 0.88 },
    META_MERGE        => { resources => {repository => 'https://github.com/olegwtf/p5-AnyEvent-HTTP-Socks'} },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/AnyEvent/HTTP/Socks.pm', # retrieve abstract from module
       AUTHOR         => 'Oleg G <oleg@cpan.org>') : ()),
);
