use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Business::FR::SSN',
    VERSION_FROM      => 'lib/Business/FR/SSN.pm',
    PREREQ_PM         => {},
    ($] >= 5.005 ?
      (ABSTRACT_FROM  => 'lib/Business/FR/SSN.pm',
       AUTHOR         => 'Fabien POTENCIER <fabpot@cpan.org>') : ()),
);
