
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "RDF model class for Catalyst based on RDF::Trine::Model.",
  "AUTHOR" => "Thiago Rondon <thiago\@aware.com.br>, Dorian Taylor <dorian\@cpan.org>",
  "BUILD_REQUIRES" => {
    "Catalyst" => 0,
    "File::Find" => 0,
    "File::Temp" => 0,
    "Test::More" => "0.88",
    "base" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Catalyst-Model-RDF",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Catalyst::Model::RDF",
  "PREREQ_PM" => {
    "Catalyst::Model" => 0,
    "Moose" => 0,
    "Moose::Util::TypeConstraints" => 0,
    "RDF::Trine::Model" => 0
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



