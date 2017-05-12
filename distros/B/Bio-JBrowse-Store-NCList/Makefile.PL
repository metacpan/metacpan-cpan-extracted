
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "modules for formatting JSON nested containment lists for use with JBrowse",
  "AUTHOR" => "Robert Buels <rbuels\@gmail.com>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Bio-JBrowse-Store-NCList",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Bio::JBrowse::Store::NCList",
  "PREREQ_PM" => {
    "Carp" => 0,
    "Fcntl" => 0,
    "File::Path" => 0,
    "File::Spec" => 0,
    "IO::File" => 0,
    "JSON" => 2,
    "List::Util" => 0,
    "POSIX" => 0,
    "PerlIO::gzip" => 0,
    "Scalar::Util" => 0,
    "Sort::External" => 0,
    "Storable" => 0,
    "base" => 0,
    "constant" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "Carp::Always" => 0,
    "Data::Dumper" => 0,
    "Exporter" => 0,
    "File::Next" => 0,
    "File::Temp" => 0,
    "Test::More" => 0
  },
  "VERSION" => "0.1",
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



