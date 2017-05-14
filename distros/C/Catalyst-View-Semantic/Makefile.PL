
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Catalyst View for Template::Semantic",
  "AUTHOR" => "Yegor Korablev <egor\@cpan.org>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Catalyst-View-Semantic",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Catalyst::View::Semantic",
  "PREREQ_PM" => {
    "Catalyst::Component::ApplicationAttribute" => 0,
    "Catalyst::View" => 0,
    "Data::Page::Pageset" => 0,
    "Moose" => 0,
    "Template::Semantic" => 0,
    "namespace::autoclean" => 0
  },
  "VERSION" => "0.002",
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



