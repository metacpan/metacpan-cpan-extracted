
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Generate PNG graphical representations of Data Matrix barcodes",
  "AUTHOR" => "Kasem Omary <kasemo\@cpan.org>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Barcode-DataMatrix-PNG",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Barcode::DataMatrix::PNG",
  "PREREQ_PM" => {
    "Any::Moose" => 0,
    "Barcode::DataMatrix" => 0,
    "Carp" => 0,
    "GD" => 0,
    "Moose" => 0
  },
  "VERSION" => "0.04",
  "test" => {
    "TESTS" => ""
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



