
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Super simple caching for Catalyst actions",
  "AUTHOR" => "Arthur Axel \"fREW\" Schmidt <frioux+cpan\@gmail.com>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Catalyst-ActionRole-PseudoCache",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Catalyst::ActionRole::PseudoCache",
  "PREREQ_PM" => {
    "Catalyst::Controller::ActionRole" => "0.12",
    "Catalyst::Plugin::Cache" => 0,
    "Catalyst::Plugin::Static::Simple" => 0,
    "Catalyst::Runtime" => "5.80013",
    "Catalyst::Test" => 0,
    "File::Spec" => 0,
    "FindBin" => 0,
    "Test::More" => "0.88",
    "Test::WWW::Mechanize::Catalyst" => 0,
    "autodie" => 0,
    "parent" => 0
  },
  "VERSION" => "1.000003",
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



