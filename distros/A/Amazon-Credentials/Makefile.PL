
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME           => 'Amazon::Credentials',
    AUTHOR         => 'Rob Lauer <rlauer6@comcast.net>',
    VERSION_FROM   => 'lib/Amazon/Credentials.pm',
    ABSTRACT       => 'AWS credentials discoverer',
    LICENSE        => 'perl',
    PL_FILES       => {},
    PREREQ_PM      => {
      'Class::Accessor' => '0.31',
      'Data::Dumper' => '2.145',
      'Date::Format' => '2.24',
      'Exporter' => '5.68',
      'File::HomeDir' => '1.00',
      'File::chdir' => '0.1008',
      'HTTP::Request' => '6.00',
      'JSON' => '2.59',
      'LWP::UserAgent' => '6.05',
      'POSIX::strptime' => '0.13',
      'Scalar::Util' => '1.5',
      'Time::Local' => '1.2300',
      'constant' => '1.27',
      'parent' => '0.225',
      'strict' => '1.07',
      'vars' => '1.02',
      'warnings' => '1.13'
    }
,
    TEST_REQUIRES  => {
      'Data::Dumper' => '2.145',
      'Date::Format' => '2.24',
      'File::Path' => '2.09',
      'File::Temp' => '0.2301',
      'JSON' => '2.59',
      'Module::Loaded' => '0.08',
      'Test::More' => '1.001014',
      'strict' => '1.07',
      'warnings' => '1.13'
    }

);
