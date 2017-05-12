
use strict;
use warnings;

use 5.001;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "a high-level interface to cddb protocol servers (freedb and CDDB)",
  "AUTHOR" => "Rocco Caputo <rcaputo\@cpan.org>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "CDDB",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "CDDB",
  "PREREQ_PM" => {
    "Carp" => "1.26",
    "Encode" => "2.51",
    "HTTP::Request" => "6.00",
    "IO::Socket" => "1.31",
    "LWP" => "6.05",
    "MIME::QuotedPrint" => "3.13",
    "Mail::Header" => "2.04",
    "Mail::Internet" => "2.04",
    "Sys::Hostname" => "1.11",
    "strict" => 0,
    "vars" => 0
  },
  "TEST_REQUIRES" => {
    "Scalar::Util" => "1.29",
    "Test::More" => "0.98",
    "warnings" => 0
  },
  "VERSION" => "1.222",
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

WriteMakefile(%WriteMakefileArgs);



