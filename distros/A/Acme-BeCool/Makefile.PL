use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Acme::BeCool',
    VERSION_FROM      => 'BeCool.pm',
    PREREQ_PM         => { LWP::Simple => 0 },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (AUTHOR         => q|Sean O'Rourke <seano@cpan.org>|) : ()),
    ABSTRACT          => 'Do what it takes to be a Cool Hacker at the moment.',
);
