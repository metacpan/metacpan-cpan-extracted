
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Collect information from multiple sources",
  "AUTHOR" => "Sawyer X <xsawyerx\@cpan.org>",
  "BUILD_REQUIRES" => {
    "File::Find" => 0,
    "File::Temp" => 0,
    "Module::Build" => "0.3601",
    "Sub::Override" => 0,
    "Test::Fatal" => 0,
    "Test::More" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30",
    "Module::Build" => "0.3601"
  },
  "DISTNAME" => "Data-Collector",
  "EXE_FILES" => [
    "bin/data-collector"
  ],
  "LICENSE" => "perl",
  "NAME" => "Data::Collector",
  "PREREQ_PM" => {
    "Carp" => 0,
    "Class::Load" => 0,
    "Data::Dumper" => 0,
    "File::HomeDir" => 0,
    "File::Spec" => 0,
    "IPC::System::Simple" => 0,
    "JSON" => 0,
    "List::MoreUtils" => 0,
    "List::Util" => 0,
    "Module::Pluggable::Object" => 0,
    "Moose" => 0,
    "Moose::Role" => 0,
    "MooseX::Getopt::Dashes" => 0,
    "MooseX::SimpleConfig" => 0,
    "MooseX::Types::Path::Class" => 0,
    "MooseX::Types::Set::Object" => 0,
    "Net::OpenSSH" => 0,
    "Set::Object" => 0,
    "YAML" => 0,
    "indirect" => 0,
    "namespace::autoclean" => 0,
    "strictures" => 1
  },
  "VERSION" => "0.15",
  "test" => {
    "TESTS" => "t/*.t t/collector/*.t t/engine/*.t t/info/*.t t/serializers/*.t"
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



