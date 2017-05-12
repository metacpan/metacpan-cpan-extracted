use 5.010000;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'DR::Msgpuck',
    VERSION_FROM      => 'lib/DR/Msgpuck.pm',
    PREREQ_PM         => {},
    ($] >= 5.005 ?
      (ABSTRACT_FROM  => 'lib/DR/Msgpuck.pm',
       AUTHOR         => 'Dmitry E. Oboukhov <unera@debian.org>') : ()),
    LIBS              => [''],
    DEFINE            => '',
    INC               => '-I.',
);
