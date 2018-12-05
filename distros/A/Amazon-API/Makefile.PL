
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME           => 'Amazon::API',
    AUTHOR         => 'Rob Lauer <rlauer6@comcast.net>',
    VERSION_FROM   => 'lib/Amazon/API.pm',
    ABSTRACT       => 'AWS API base class',
    LICENSE        => 'perl',
    PL_FILES       => {},
    PREREQ_PM      => {
      'AWS::Signature4' => 0,
      'Amazon::API::Error' => 0,
      'Amazon::Credentials' => 0,
      'Class::Accessor' => 0,
      'Data::Dumper' => 0,
      'Exporter' => 0,
      'HTTP::Request' => 0,
      'JSON' => 0,
      'LWP::UserAgent' => 0,
      'Scalar::Util' => 0,
      'XML::Simple' => 0,
      'parent' => 0,
      'strict' => 0,
      'vars' => 0,
      'warnings' => 0
    }
,
    TEST_REQUIRES  => {
      'Amazon::API' => 0,
      'Test::More' => 0
    }

);
