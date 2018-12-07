
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
      'AWS::Signature4' => '1.02',
      'Amazon::Credentials' => '1.0.7',
      'Class::Accessor' => '0.31',
      'Data::Dumper' => '2.145',
      'Exporter' => '5.68',
      'HTTP::Request' => '6.00',
      'JSON' => '2.59',
      'LWP::UserAgent' => '6.05',
      'Scalar::Util' => '1.5',
      'XML::Simple' => '2.20',
      'parent' => '0.225',
      'strict' => '1.07',
      'vars' => '1.02',
      'warnings' => '1.13'
    }
,
    TEST_REQUIRES  => {
      'Amazon::API' => '1.1.4',
      'Test::More' => '1.001014'
    }

);
