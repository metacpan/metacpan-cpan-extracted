
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME           => 'Amazon::SecretsManager',
    AUTHOR         => 'Rob Lauer <rlauer6@comcast.net>',
    VERSION_FROM   => 'lib/Amazon/SecretsManager.pm',
    ABSTRACT       => 'AWS Secrets Manager',
    LICENSE        => 'perl',
    PL_FILES       => {},
    EXE_FILES      =>     []
,
    PREREQ_PM      => {
      'Amazon::API' => '1.1.6',
      'Data::UUID' => '1.219',
      'parent' => '0.225',
      'strict' => '1.07',
      'vars' => '1.02',
      'warnings' => '1.13'
    },
    TEST_REQUIRES  =>     {}

);
