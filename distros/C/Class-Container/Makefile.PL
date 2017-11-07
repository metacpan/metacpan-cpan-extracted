
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Glues object frameworks together transparently",
  "AUTHOR" => "Ken Williams <kwilliams\@cpan.org>",
  "BUILD_REQUIRES" => {
    "Module::Build" => "0.3601"
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30",
    "Module::Build" => "0.3601"
  },
  "DISTNAME" => "Class-Container",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Class::Container",
  "PREREQ_PM" => {
    "B::Deparse" => 0,
    "Carp" => 0,
    "Params::Validate" => 0,
    "Scalar::Util" => 0,
    "strict" => 0,
    "vars" => 0
  },
  "TEST_REQUIRES" => {
    "File::Spec" => 0,
    "Test" => 0
  },
  "VERSION" => "0.13",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "B::Deparse" => 0,
  "Carp" => 0,
  "File::Spec" => 0,
  "Module::Build" => "0.3601",
  "Params::Validate" => 0,
  "Scalar::Util" => 0,
  "Test" => 0,
  "strict" => 0,
  "vars" => 0
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



