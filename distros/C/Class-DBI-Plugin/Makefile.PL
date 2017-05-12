use 5.006;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Class::DBI::Plugin',
    VERSION_FROM      => 'Plugin.pm',
    PREREQ_PM         => { 'Class::DBI' => 0.90 },
    ($] >= 5.005 ?
      (ABSTRACT_FROM  => 'Plugin.pm',
       AUTHOR         => 'Jean-Christophe Zeus <mail@jczeus.com>') : ()),
);
