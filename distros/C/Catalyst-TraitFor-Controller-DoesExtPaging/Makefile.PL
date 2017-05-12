
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Paginate DBIx::Class::ResultSets for ExtJS consumption",
  "AUTHOR" => "Arthur Axel \"fREW\" Schmidt <frioux+cpan\@gmail.com>",
  "BUILD_REQUIRES" => {
    "Catalyst::Model::DBIC::Schema" => "0.29",
    "Catalyst::Test" => 0,
    "Catalyst::View::JSON" => "0.26",
    "FindBin" => 0,
    "SQL::Translator" => "0.11016",
    "Test::Deep" => 0,
    "Test::More" => "0.92"
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Catalyst-TraitFor-Controller-DoesExtPaging",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Catalyst::TraitFor::Controller::DoesExtPaging",
  "PREREQ_PM" => {
    "Catalyst::Runtime" => "5.8",
    "Catalyst::TraitFor::Controller::DBIC::DoesPaging" => "0.093200",
    "Web::Util::ExtPaging" => "0.001000"
  },
  "VERSION" => "1.000001",
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



