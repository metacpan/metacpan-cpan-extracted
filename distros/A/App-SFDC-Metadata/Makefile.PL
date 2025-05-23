# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v5.039.
use strict;
use warnings;



use ExtUtils::MakeMaker;

use File::ShareDir::Install;
$File::ShareDir::Install::INCLUDE_DOTFILES = 1;
$File::ShareDir::Install::INCLUDE_DOTDIRS = 1;
install_share dist => "share";


my %WriteMakefileArgs = (
  "ABSTRACT" => "Metadata tools module for App::SFDC",
  "AUTHOR" => "Alexander Brett <alexander.brett\@sophos.com> L<http://alexander-brett.co.uk>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0,
    "File::ShareDir::Install" => "0.06"
  },
  "DISTNAME" => "App-SFDC-Metadata",
  "LICENSE" => "mit",
  "NAME" => "App::SFDC::Metadata",
  "PREREQ_PM" => {
    "App::SFDC" => "0.14",
    "App::SFDC::Role::Credentials" => 0,
    "App::SFDC::Role::Logging" => 0,
    "Data::Dumper" => 0,
    "File::Find" => 0,
    "File::HomeDir" => 0,
    "File::Path" => 0,
    "File::Share" => 0,
    "FindBin" => 0,
    "Log::Log4perl" => 0,
    "Moo" => 0,
    "Moo::Role" => 0,
    "MooX::Options" => 0,
    "WWW::SFDC::Manifest" => 0,
    "WWW::SFDC::Zip" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.21",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "App::SFDC" => "0.14",
  "App::SFDC::Role::Credentials" => 0,
  "App::SFDC::Role::Logging" => 0,
  "Data::Dumper" => 0,
  "File::Find" => 0,
  "File::HomeDir" => 0,
  "File::Path" => 0,
  "File::Share" => 0,
  "FindBin" => 0,
  "Log::Log4perl" => 0,
  "Moo" => 0,
  "Moo::Role" => 0,
  "MooX::Options" => 0,
  "WWW::SFDC::Manifest" => 0,
  "WWW::SFDC::Zip" => 0,
  "strict" => 0,
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

{
package
MY;
use File::ShareDir::Install qw(postamble);
}
