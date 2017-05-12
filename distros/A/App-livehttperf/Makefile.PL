
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Real life web performance testing tool",
  "AUTHOR" => "Alex J. G. Burzy\305\204ski <ajgb\@cpan.org>",
  "BUILD_REQUIRES" => {
    "File::Find" => 0,
    "File::Temp" => 0,
    "Module::Build" => "0.3601",
    "Test::More" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30",
    "Module::Build" => "0.3601"
  },
  "DISTNAME" => "App-livehttperf",
  "EXE_FILES" => [
    "bin/livehttperf"
  ],
  "LICENSE" => "perl",
  "NAME" => "App::livehttperf",
  "PREREQ_PM" => {
    "Excel::Writer::XLSX" => 0,
    "Getopt::Long" => 0,
    "HTTP::Request" => 0,
    "HTTP::Response" => 0,
    "LWP::UserAgent" => 0,
    "List::Util" => 0,
    "Number::Bytes::Human" => 0,
    "Parallel::ForkManager" => 0,
    "Statistics::Descriptive" => 0,
    "Text::TabularDisplay" => 0,
    "Time::Elapsed" => 0,
    "Time::HiRes" => 0,
    "strict" => 0,
    "utf8" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.03",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.56) } ) {
  my $br = delete $WriteMakefileArgs{BUILD_REQUIRES};
  my $pp = $WriteMakefileArgs{PREREQ_PM};
  for my $mod ( keys %$br ) {
    if ( exists $pp->{$mod} ) {
      $pp->{$mod} = $br->{$mod} if $br->{$mod} > $pp->{$mod};
    }
    else {
      $pp->{$mod} = $br->{$mod};
    }
  }
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



