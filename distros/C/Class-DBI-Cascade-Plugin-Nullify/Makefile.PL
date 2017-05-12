use strict;
use warnings;
use ExtUtils::MakeMaker;
WriteMakefile
(
  NAME => 'Class::DBI::Cascade::Plugin::Nullify',
  VERSION_FROM => 'lib/Class/DBI/Cascade/Plugin/Nullify.pm',
  PREREQ_PM => {
    'Class::DBI' => '0',
    'Class::ISA' => '0',
    'Test::More' => '0'
  },
  dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
  clean => { FILES => 'Class-DBI-Cascade-Plugin-Nullify-*' },
);