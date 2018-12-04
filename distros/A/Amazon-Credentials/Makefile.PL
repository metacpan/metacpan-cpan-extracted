
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME           => 'Amazon::Credentials',
    AUTHOR         => 'Rob Lauer <rlauer6@comcast.net>',
    VERSION_FROM   => 'lib/Amazon/Credentials.pm',
    ABSTRACT       => 'AWS',
    LICENSE        => 'perl',
    PL_FILES       => {},
    PREREQ_PM      => {
      'Class::Accessor' => 0,
      'Data::Dumper' => 0,
      'Date::Format' => 0,
      'Exporter' => 0,
      'File::HomeDir' => 0,
      'File::chdir' => 0,
      'HTTP::Request' => 0,
      'JSON' => 0,
      'LWP::UserAgent' => 0,
      'POSIX::strptime' => 0,
      'Scalar::Util' => 0,
      'Time::Local' => 0,
      'constant' => 0,
      'parent' => 0,
      'strict' => 0,
      'vars' => 0,
      'warnings' => 0
    }
,
    TEST_REQUIRES  => {
      'Data::Dumper' => 0,
      'Date::Format' => 0,
      'File::Path' => 0,
      'File::Temp' => 0,
      'JSON' => 0,
      'Module::Loaded' => 0,
      'Test::More' => 0,
      'strict' => 0,
      'warnings' => 0
    }

);
