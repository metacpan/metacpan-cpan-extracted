use 5.005000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'AnyEvent::Whois::Raw',
    VERSION_FROM      => 'lib/AnyEvent/Whois/Raw.pm', # finds $VERSION
    LICENSE           => 'perl',
    PREREQ_PM         => { 'Net::Whois::Raw' => 2.31, 'AnyEvent' => 3.3, 'AnyEvent::HTTP' => 1.43 },
    BUILD_REQUIRES    => { 'Test::More' => 0.88 },
    META_MERGE        => { resources => {repository => 'https://github.com/olegwtf/p5-AnyEvent-Whois-Raw'} },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/AnyEvent/Whois/Raw.pm',
       AUTHOR         => 'Oleg G <oleg@cpan.org>') : ()),
);
