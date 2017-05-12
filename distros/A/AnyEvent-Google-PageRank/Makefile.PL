use 5.005000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME               => 'AnyEvent::Google::PageRank',
    LICENSE            => 'perl',
    VERSION_FROM       => 'lib/AnyEvent/Google/PageRank.pm',
    CONFIGURE_REQUIRES => { 'ExtUtils::MakeMaker' => 6.52 },
    PREREQ_PM          => { 'AnyEvent::HTTP' => 0, 'WWW::Google::PageRank' => 0, 'URI::Escape' => 0 },
    BUILD_REQUIRES     => { 'Test::More' => 0.88 },
    META_MERGE         => { resources => {repository => 'https://github.com/olegwtf/p5-AnyEvent-Google-PageRank'} },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM   => 'lib/AnyEvent/Google/PageRank.pm',
       AUTHOR          => 'Oleg G <oleg@cpan.org>') : ()),
);
