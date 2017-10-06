use ExtUtils::MakeMaker;
use v5.8.0;

my %WriteMakefileArgs = (
  "ABSTRACT" => "Get and search AWS IP ranges in a caching, auto-refreshing way",
  "AUTHOR" => "David Farrell <dnmfarrell\@cpan.org>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME" => "AWS-IP",
  "LICENSE" => "perl",
  "NAME" => "AWS::IP",
  "VERSION_FROM" => 'lib/AWS/IP.pm',
  "PREREQ_PM" => {
    "Cache::File" => 0,
    "Carp" => 0,
    "File::Temp" => 0,
    "HTTP::Tiny" => 0,
    "IO::Socket::SSL" => "1.56",
    "JSON::XS" => 0,
    "Net::CIDR::Set" => 0,
    "Net::SSLeay" => "1.49",
    "constant" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "Test::More" => 0
  },
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Cache::File" => 0,
  "Carp" => 0,
  "File::Temp" => 0,
  "HTTP::Tiny" => 0,
  "IO::Socket::SSL" => "1.56",
  "JSON::XS" => 0,
  "Net::CIDR::Set" => 0,
  "Net::SSLeay" => "1.49",
  "Test::More" => 0,
  "constant" => 0,
  "strict" => 0,
  "warnings" => 0
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);
