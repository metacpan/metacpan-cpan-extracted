
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Data::SearchEngine backend for Solr",
  "AUTHOR" => "Cory G Watson <gphat\@cpan.org>",
  "BUILD_REQUIRES" => {
    "Data::SearchEngine::Query" => 0,
    "HTTP::Headers" => 0,
    "HTTP::Response" => 0,
    "Test::More" => 0,
    "WebService::Solr::Response" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Data-SearchEngine-Solr",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Data::SearchEngine::Solr",
  "PREREQ_PM" => {
    "Clone" => 0,
    "Data::SearchEngine" => "0.28",
    "Data::SearchEngine::Item" => 0,
    "Data::SearchEngine::Paginator" => 0,
    "Data::SearchEngine::Results" => 0,
    "Data::SearchEngine::Results::Spellcheck::Suggestion" => 0,
    "Moose" => 0,
    "Time::HiRes" => 0,
    "WebService::Solr" => "0.11"
  },
  "VERSION" => "0.20",
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



