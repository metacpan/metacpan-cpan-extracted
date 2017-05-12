
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Tools to make migrating your DBIx::Class databases easier",
  "AUTHOR" => "John Napiorkowski <jjnapiork\@cpan.org>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "DBIx-Class-Migration",
  "EXE_FILES" => [
    "bin/dbic-migration"
  ],
  "LICENSE" => "perl",
  "NAME" => "DBIx::Class::Migration",
  "PREREQ_PM" => {
    "Class::Load" => 0,
    "Config::MySQL" => "0.02",
    "DBD::SQLite" => "1.35",
    "DBIx::Class::DeploymentHandler" => "0.002100",
    "DBIx::Class::Fixtures" => "1.001016",
    "DBIx::Class::Schema::Loader" => "0.07017",
    "Devel::PartialDump" => 0,
    "File::Copy" => 0,
    "File::Path" => 0,
    "File::ShareDir::ProjectDistDir" => "0.003001",
    "File::Spec" => 0,
    "File::Temp" => 0,
    "JSON::XS" => "2.32",
    "Moose" => 0,
    "MooseX::Attribute::ENV" => "0.02",
    "MooseX::Getopt" => "0.45",
    "MooseX::Traits::Pluggable" => 0,
    "MooseX::Types" => 0,
    "MooseX::Types::LoadableClass" => 0,
    "Pod::Parser" => "1.51",
    "SQL::Translator" => "0.11010",
    "Text::Brew" => 0,
    "version" => "0.77"
  },
  "TEST_REQUIRES" => {
    "File::Path" => 0,
    "File::Spec::Functions" => 0,
    "Test::Most" => 0,
    "Test::Requires" => 0
  },
  "VERSION" => "0.044",
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



