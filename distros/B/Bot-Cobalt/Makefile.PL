# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v6.006.
use strict;
use warnings;

use 5.012001;

use ExtUtils::MakeMaker;

use File::ShareDir::Install;
$File::ShareDir::Install::INCLUDE_DOTFILES = 1;
$File::ShareDir::Install::INCLUDE_DOTDIRS = 1;
install_share dist => "share";


my %WriteMakefileArgs = (
  "ABSTRACT" => "IRC darkbot-alike plus plugin authoring sugar",
  "AUTHOR" => "Jon Portnoy <avenj\@cobaltirc.org>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0,
    "File::ShareDir::Install" => "0.06"
  },
  "DISTNAME" => "Bot-Cobalt",
  "EXE_FILES" => [
    "bin/cobalt2",
    "bin/cobalt2-dbdump",
    "bin/cobalt2-installer",
    "bin/cobalt2-plugin-installcf"
  ],
  "LICENSE" => "perl",
  "MIN_PERL_VERSION" => "5.012001",
  "NAME" => "Bot::Cobalt",
  "PREREQ_PM" => {
    "App::bmkpasswd" => 2,
    "DB_File" => 0,
    "Devel::StackTrace" => 0,
    "Digest::MD5" => 0,
    "Exporter::Tiny" => 0,
    "Fcntl" => 0,
    "File::ShareDir" => 1,
    "HTTP::Request" => 0,
    "HTTP::Response" => 0,
    "IRC::Utils" => "0.12",
    "Import::Into" => 0,
    "JSON::MaybeXS" => 0,
    "List::Objects::Types" => "1.002",
    "List::Objects::WithUtils" => "2.008",
    "Module::Runtime" => 0,
    "Moo" => "1.006",
    "Net::IP::Minimal" => "0.04",
    "POE" => "1.3",
    "POE::Component::Client::DNS" => 0,
    "POE::Component::Client::HTTP" => "0.947",
    "POE::Component::Client::Keepalive" => 0,
    "POE::Component::IRC" => "6.78",
    "POE::Component::Resolver" => "0.920",
    "POE::Component::Syndicator" => "0.06",
    "Path::Tiny" => "0.05",
    "Proc::PID::File" => "1.26",
    "Try::Tiny" => 0,
    "Type::Tiny" => "0.04",
    "Types::Path::Tiny" => "0.005",
    "URI::Escape" => 0,
    "YAML::XS" => "0.34",
    "strictures" => 2
  },
  "TEST_REQUIRES" => {
    "Capture::Tiny" => 0,
    "ExtUtils::MakeMaker" => 0,
    "File::Spec" => 0,
    "Test::File::ShareDir" => 0,
    "Test::More" => "0.88"
  },
  "VERSION" => "0.021003",
  "test" => {
    "TESTS" => "t/*.t t/01_utils/*.t t/02_logger/*.t t/03_conf/*.t t/04_core/*.t t/05_irc/*.t t/06_db/*.t t/07_plugins/*.t t/08_cmds/*.t"
  }
);


my %FallbackPrereqs = (
  "App::bmkpasswd" => 2,
  "Capture::Tiny" => 0,
  "DB_File" => 0,
  "Devel::StackTrace" => 0,
  "Digest::MD5" => 0,
  "Exporter::Tiny" => 0,
  "ExtUtils::MakeMaker" => 0,
  "Fcntl" => 0,
  "File::ShareDir" => 1,
  "File::Spec" => 0,
  "HTTP::Request" => 0,
  "HTTP::Response" => 0,
  "IRC::Utils" => "0.12",
  "Import::Into" => 0,
  "JSON::MaybeXS" => 0,
  "List::Objects::Types" => "1.002",
  "List::Objects::WithUtils" => "2.008",
  "Module::Runtime" => 0,
  "Moo" => "1.006",
  "Net::IP::Minimal" => "0.04",
  "POE" => "1.3",
  "POE::Component::Client::DNS" => 0,
  "POE::Component::Client::HTTP" => "0.947",
  "POE::Component::Client::Keepalive" => 0,
  "POE::Component::IRC" => "6.78",
  "POE::Component::Resolver" => "0.920",
  "POE::Component::Syndicator" => "0.06",
  "Path::Tiny" => "0.05",
  "Proc::PID::File" => "1.26",
  "Test::File::ShareDir" => 0,
  "Test::More" => "0.88",
  "Try::Tiny" => 0,
  "Type::Tiny" => "0.04",
  "Types::Path::Tiny" => "0.005",
  "URI::Escape" => 0,
  "YAML::XS" => "0.34",
  "strictures" => 2
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
