
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Fusing together AnyEvent and Net::SIP",
  "AUTHOR" => "Sawyer X <xsawyerx\@cpan.org>",
  "BUILD_REQUIRES" => {
    "Cwd" => 0,
    "Data::Dumper" => 0,
    "Digest::MD5" => 0,
    "File::Find" => 0,
    "File::Temp" => 0,
    "IO::Socket" => 0,
    "List::Util" => 0,
    "Module::Build" => "0.3601",
    "Net::SIP" => 0,
    "Net::SIP::Blocker" => 0,
    "Net::SIP::Debug" => 0,
    "Net::SIP::Dropper" => 0,
    "Net::SIP::Dropper::ByField" => 0,
    "Net::SIP::Dropper::ByIPPort" => 0,
    "Net::SIP::Leg" => 0,
    "Net::SIP::NATHelper::Client" => 0,
    "Net::SIP::NATHelper::Local" => 0,
    "Net::SIP::NATHelper::Server" => 0,
    "Net::SIP::ReceiveChain" => 0,
    "Net::SIP::SDP" => 0,
    "Test::More" => 0,
    "base" => 0,
    "fields" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30",
    "Module::Build" => "0.3601"
  },
  "DISTNAME" => "AnyEvent-SIP",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "AnyEvent::SIP",
  "PREREQ_PM" => {
    "AnyEvent" => 0,
    "AnyEvent::AggressiveIdle" => 0,
    "Net::SIP::Dispatcher::Eventloop" => 0,
    "Net::SIP::Util" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.002",
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



