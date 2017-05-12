
use strict;
use warnings;

BEGIN { require 5.008; }

use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'Network-related value objects',
  'AUTHOR' => 'Marcel Gruenauer <marcel@cpan.org>',
  'BUILD_REQUIRES' => {
    'Carp' => '0',
    'Class::Value' => '0',
    'English' => '0',
    'Error' => '0',
    'File::Find' => '0',
    'File::Temp' => '0',
    'Scalar::Util' => '0',
    'Test::CompanionClasses' => '0',
    'Test::More' => '0.94'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'Class-Value-Net',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'Class::Value::Net',
  'PREREQ_PM' => {
    'Class::Value::Boolean' => '0',
    'Class::Value::Enum' => '0',
    'Class::Value::Exception::Base' => '0',
    'Class::Value::SemanticAdapter' => '0',
    'Class::Value::String' => '0',
    'Class::Value::Test' => '0',
    'Data::Semantic::Net::IPAddress::TestData::IPv4' => '1.101750',
    'Data::Semantic::Net::IPAddress::TestData::IPv6' => '0',
    'Error::Hierarchy::Mixin' => '0',
    'Error::Hierarchy::Test' => '0',
    'Test::CompanionClasses::Base' => '0',
    'Test::More' => '0',
    'constant' => '0',
    'parent' => '0'
  },
  'VERSION' => '1.110250',
  'test' => {
    'TESTS' => 't/*.t'
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



