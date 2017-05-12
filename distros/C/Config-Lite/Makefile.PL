use 5.008008;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'Config::Lite',
    VERSION_FROM      => 'lib/Config/Lite.pm',
    PREREQ_PM         => {},
    ($] >= 5.005 ?
      (ABSTRACT_FROM  => 'lib/Config/Lite.pm',
       AUTHOR         => 'Chen Gang <yikuyiku.com@gmail.com>') : ()),
);
