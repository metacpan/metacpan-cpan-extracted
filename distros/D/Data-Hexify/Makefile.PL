# $id$

use 5.006;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Data::Hexify',
    VERSION_FROM      => 'lib/Data/Hexify.pm',
    PREREQ_PM         => { qw(Test::More) },
    ($] >= 5.005 ?
      (ABSTRACT_FROM  => 'lib/Data/Hexify.pm',
       AUTHOR         => 'Johan Vromans <jvromans@squirrel.nl>') : ()),
);
