# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v6.009.
use strict;
use warnings;

use 5.006;

use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT" => "OAuth2 services for Catalyst",
  "AUTHOR" => "Eden Cardim <edencardim\@gmail.com>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME" => "CatalystX-OAuth2",
  "LICENSE" => "perl",
  "MIN_PERL_VERSION" => "5.006",
  "NAME" => "CatalystX::OAuth2",
  "PREREQ_PM" => {
    "Class::Load" => 0,
    "DBIx::Class" => 0,
    "DBIx::Class::ResultSet" => 0,
    "DBIx::Class::Schema" => 0,
    "HTTP::Request::Common" => 0,
    "JSON::Any" => 0,
    "LWP::UserAgent" => 0,
    "Moose" => 0,
    "Moose::Role" => 0,
    "Moose::Util" => 0,
    "Moose::Util::TypeConstraints" => 0,
    "MooseX::NonMoose" => 0,
    "MooseX::SetOnce" => 0,
    "MooseX::Types::Common::String" => 0,
    "Scalar::Util" => 0,
    "Try::Tiny" => 0,
    "URI" => 0,
    "base" => 0,
    "parent" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "Catalyst" => 0,
    "Catalyst::Controller" => 0,
    "Catalyst::Controller::ActionRole" => 0,
    "Catalyst::Model::DBIC::Schema" => 0,
    "Catalyst::Plugin::Authentication" => 0,
    "Catalyst::Plugin::ConfigLoader" => 0,
    "Catalyst::Plugin::Session" => 0,
    "Catalyst::Plugin::Session::State::Cookie" => 0,
    "Catalyst::Test" => 0,
    "Devel::Dwarn" => 0,
    "File::Spec" => 0,
    "HTTP::Request" => 0,
    "IO::Handle" => 0,
    "IPC::Open3" => 0,
    "Plack::Builder" => 0,
    "Plack::Test" => 0,
    "SQL::Translator" => "0.11006",
    "Test::Exception" => 0,
    "Test::MockObject" => 0,
    "Test::More" => 0,
    "Test::WWW::Mechanize::PSGI" => 0,
    "blib" => "1.01",
    "lib" => 0,
    "namespace::autoclean" => 0,
    "strictures" => 1
  },
  "VERSION" => "0.001009",
  "test" => {
    "TESTS" => "t/*.t t/integration/*.t t/unit/*.t"
  }
);


my %FallbackPrereqs = (
  "Catalyst" => 0,
  "Catalyst::Controller" => 0,
  "Catalyst::Controller::ActionRole" => 0,
  "Catalyst::Model::DBIC::Schema" => 0,
  "Catalyst::Plugin::Authentication" => 0,
  "Catalyst::Plugin::ConfigLoader" => 0,
  "Catalyst::Plugin::Session" => 0,
  "Catalyst::Plugin::Session::State::Cookie" => 0,
  "Catalyst::Test" => 0,
  "Class::Load" => 0,
  "DBIx::Class" => 0,
  "DBIx::Class::ResultSet" => 0,
  "DBIx::Class::Schema" => 0,
  "Devel::Dwarn" => 0,
  "File::Spec" => 0,
  "HTTP::Request" => 0,
  "HTTP::Request::Common" => 0,
  "IO::Handle" => 0,
  "IPC::Open3" => 0,
  "JSON::Any" => 0,
  "LWP::UserAgent" => 0,
  "Moose" => 0,
  "Moose::Role" => 0,
  "Moose::Util" => 0,
  "Moose::Util::TypeConstraints" => 0,
  "MooseX::NonMoose" => 0,
  "MooseX::SetOnce" => 0,
  "MooseX::Types::Common::String" => 0,
  "Plack::Builder" => 0,
  "Plack::Test" => 0,
  "SQL::Translator" => "0.11006",
  "Scalar::Util" => 0,
  "Test::Exception" => 0,
  "Test::MockObject" => 0,
  "Test::More" => 0,
  "Test::WWW::Mechanize::PSGI" => 0,
  "Try::Tiny" => 0,
  "URI" => 0,
  "base" => 0,
  "blib" => "1.01",
  "lib" => 0,
  "namespace::autoclean" => 0,
  "parent" => 0,
  "strict" => 0,
  "strictures" => 1,
  "warnings" => 0
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);
