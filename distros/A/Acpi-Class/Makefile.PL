
use strict;
use warnings;

use 5.012;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Inspired in Acpi::Battery, this module gets the contents of the directory '/sys/class' in terms of 'classes' (ArrayRef of directories in /sys/class), 'devices' (ArrayRef of subdirectory in class) and 'attributes' (HashRef attributes => values, from the contents of devices directory).",
  "AUTHOR" => "mimosinnet <mimosinet at cpan.org>",
  "BUILD_REQUIRES" => {
    "FindBin" => 0,
    "List::Compare" => 0,
    "Test::More" => 0,
    "utf8" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Acpi-Class",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Acpi::Class",
  "PREREQ_PM" => {
    "Carp" => 0,
    "List::Compare" => 0,
    "Object::Tiny::RW" => 0,
    "Object::Tiny::XS" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.003",
  "test" => {
    "TESTS" => "t/*.t t/Acpi/*.t t/Acpi/Class/*.t"
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



