
use strict;
use warnings;

use 5.008001;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Virtual Filesystem backed by Content-Addressable Storage",
  "AUTHOR" => "Michael Conrad <mconrad\@intellitree.com>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "DataStore-CAS-FS",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "DataStore::CAS::FS",
  "PREREQ_PM" => {
    "Carp" => 0,
    "DataStore::CAS" => "0.02",
    "Fcntl" => 0,
    "File::Spec" => "3.33",
    "File::Spec::Functions" => 0,
    "JSON" => "2.53",
    "Moo" => "1.000007",
    "Scalar::Util" => 0,
    "Socket" => 0,
    "Try::Tiny" => "0.11",
    "overload" => 0,
    "parent" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "Data::Dumper" => 0,
    "Digest" => 0,
    "Path::Class" => 0,
    "Test::More" => 0
  },
  "VERSION" => "0.011000",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  my $tr = delete $WriteMakefileArgs{TEST_REQUIRES};
  my $br = $WriteMakefileArgs{BUILD_REQUIRES};
  for my $mod ( keys %$tr ) {
    if ( exists $br->{$mod} ) {
      $br->{$mod} = $tr->{$mod} if $tr->{$mod} > $br->{$mod};
    }
    else {
      $br->{$mod} = $tr->{$mod};
    }
  }
}

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

if ( $^O eq 'MSWin32' ) {
	$WriteMakefileArgs{PREREQ_PM}{'Win32API::File'} = '0';
}

WriteMakefile(%WriteMakefileArgs);



