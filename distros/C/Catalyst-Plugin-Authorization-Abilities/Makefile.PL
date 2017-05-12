
use strict;
use warnings;

use 5.006;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Ability based authorization for Catalyst/DBIx::Class apps, based on Catalyst::Plugin::Authorization::Roles",
  "AUTHOR" => "Ido Perlmuter <ido\@ido50.net>",
  "BUILD_REQUIRES" => {
    "Carp" => 0,
    "Catalyst" => 0,
    "Catalyst::Authentication::Store::DBIx::Class" => 0,
    "Catalyst::Controller" => 0,
    "Catalyst::Model::DBIC::Schema" => 0,
    "Catalyst::Plugin::Authentication" => 0,
    "Catalyst::Plugin::Session" => 0,
    "Catalyst::Plugin::Session::State::Cookie" => 0,
    "Catalyst::Plugin::Session::Store::FastMmap" => 0,
    "Catalyst::Runtime" => "5.80",
    "Catalyst::ScriptRunner" => 0,
    "Catalyst::Test" => 0,
    "Catalyst::View::TT" => 0,
    "CatalystX::SimpleLogin" => 0,
    "Config::JFDI" => 0,
    "DBD::SQLite" => 0,
    "DBIx::Class::Core" => 0,
    "DBIx::Class::DateTime::Epoch" => 0,
    "DBIx::Class::EncodedColumn" => 0,
    "DBIx::Class::Schema" => 0,
    "FindBin" => 0,
    "HTML::FormFu" => 0,
    "HTTP::Request::Common" => 0,
    "Hash::Merge" => 0,
    "Module::Install::Catalyst" => 0,
    "Moose" => 0,
    "MooseX::NonMoose" => 0,
    "MooseX::Types::Path::Class" => 0,
    "Path::Class" => 0,
    "SQL::Translator" => 0,
    "Test::More" => 0,
    "UNIVERSAL::require" => 0,
    "base" => 0,
    "inc::Module::Install" => 0,
    "namespace::autoclean" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Catalyst-Plugin-Authorization-Abilities",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Catalyst::Plugin::Authorization::Abilities",
  "PREREQ_PM" => {
    "Catalyst::Exception" => 0,
    "Scalar::Util" => 0,
    "strict" => 0,
    "version" => "0.77",
    "warnings" => 0
  },
  "VERSION" => "v0.31.0",
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



