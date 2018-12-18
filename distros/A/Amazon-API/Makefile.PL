
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
      'Amazon::Credentials' => '1.0.10',
      'Class::Accessor' => '0.51',
      'Data::Dumper' => '2.170',
      'Exporter' => '5.73',
      'HTTP::Request' => '6.18',
      'JSON' => '4.00',
      'LWP::UserAgent' => '6.36',
      'Scalar::Util' => '1.5',
      'XML::Simple' => '2.25',
      'parent' => '0.236',
      'strict' => '1.11',
      'vars' => '1.04',
      'warnings' => '1.42'
    }
,
    TEST_REQUIRES  => {
      'Test::More' => '1.302133'
    }

);
