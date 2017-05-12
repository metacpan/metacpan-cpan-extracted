use 5.008008;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'Carp::Perror',
    VERSION_FROM      => 'lib/Carp/Perror.pm', 
    PREREQ_PM         => {}, 
    ($] >= 5.005 ?     
      (ABSTRACT_FROM  => 'lib/Carp/Perror.pm', 
       AUTHOR         => 'Chen Gang <chengang@apple.com>') : ()),
);
