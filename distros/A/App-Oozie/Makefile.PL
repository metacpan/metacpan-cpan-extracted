# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v6.032.
use strict;
use warnings;

use 5.014;

use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT" => "Tooling/wrappers for Oozie job deployment and scheduling",
  "AUTHOR" => "David Morel, Burak Gursoy",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME" => "App-Oozie",
  "EXE_FILES" => [
    "bin/oozie-tool"
  ],
  "LICENSE" => "perl",
  "MIN_PERL_VERSION" => "5.014",
  "NAME" => "App::Oozie",
  "PREREQ_PM" => {
    "Archive::Zip" => 0,
    "Carp" => 0,
    "Carp::Always" => 0,
    "Clone" => 0,
    "Config::General" => 0,
    "Config::Properties" => 0,
    "Cwd" => 0,
    "Data::Dumper" => 0,
    "Date::Format" => 0,
    "Date::Parse" => 0,
    "DateTime" => 0,
    "DateTime::Format::Duration" => 0,
    "DateTime::Format::Strptime" => 0,
    "Email::Valid" => 0,
    "Exporter" => 0,
    "Fcntl" => 0,
    "File::Basename" => 0,
    "File::Find" => 0,
    "File::Find::Rule" => 0,
    "File::Path" => 0,
    "File::Spec" => 0,
    "File::Spec::Functions" => 0,
    "File::Temp" => 0,
    "Getopt::Long" => 0,
    "Git::Repository" => 0,
    "Graph::Directed" => 0,
    "Hash::Flatten" => 0,
    "IO::Interactive" => 0,
    "IPC::Cmd" => 0,
    "JSON" => 0,
    "List::MoreUtils" => 0,
    "List::Util" => 0,
    "Log::Log4perl" => 0,
    "Moo" => 0,
    "Moo::Role" => 0,
    "MooX::Options" => "4.103",
    "Net::Hadoop::Oozie" => 0,
    "Net::Hadoop::WebHDFS::LWP" => "0.012",
    "Net::Hadoop::YARN::NameNode::JMX" => 0,
    "Path::Tiny" => 0,
    "Ref::Util" => 0,
    "Scalar::Util" => 0,
    "Sub::Quote" => 0,
    "Sys::Hostname" => 0,
    "Template" => "3.102",
    "Template::App::ttree" => 0,
    "Text::Glob" => 0,
    "Text::Trim" => 0,
    "Time::Duration" => 0,
    "Time::HiRes" => 0,
    "Type::Library" => 0,
    "Type::Tiny" => 0,
    "Type::Utils" => 0,
    "Types::Standard" => 0,
    "XML::Compile::Cache" => 0,
    "XML::Compile::Util" => 0,
    "XML::LibXML" => 0,
    "XML::LibXML::Simple" => 0,
    "XML::Twig" => 0,
    "YAML::XS" => 0,
    "constant" => 0,
    "namespace::autoclean" => 0,
    "overload" => 0,
    "parent" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0,
    "File::Spec" => 0,
    "IO::Handle" => 0,
    "IPC::Open3" => 0,
    "Test::More" => 0
  },
  "VERSION" => "0.020",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Archive::Zip" => 0,
  "Carp" => 0,
  "Carp::Always" => 0,
  "Clone" => 0,
  "Config::General" => 0,
  "Config::Properties" => 0,
  "Cwd" => 0,
  "Data::Dumper" => 0,
  "Date::Format" => 0,
  "Date::Parse" => 0,
  "DateTime" => 0,
  "DateTime::Format::Duration" => 0,
  "DateTime::Format::Strptime" => 0,
  "Email::Valid" => 0,
  "Exporter" => 0,
  "ExtUtils::MakeMaker" => 0,
  "Fcntl" => 0,
  "File::Basename" => 0,
  "File::Find" => 0,
  "File::Find::Rule" => 0,
  "File::Path" => 0,
  "File::Spec" => 0,
  "File::Spec::Functions" => 0,
  "File::Temp" => 0,
  "Getopt::Long" => 0,
  "Git::Repository" => 0,
  "Graph::Directed" => 0,
  "Hash::Flatten" => 0,
  "IO::Handle" => 0,
  "IO::Interactive" => 0,
  "IPC::Cmd" => 0,
  "IPC::Open3" => 0,
  "JSON" => 0,
  "List::MoreUtils" => 0,
  "List::Util" => 0,
  "Log::Log4perl" => 0,
  "Moo" => 0,
  "Moo::Role" => 0,
  "MooX::Options" => "4.103",
  "Net::Hadoop::Oozie" => 0,
  "Net::Hadoop::WebHDFS::LWP" => "0.012",
  "Net::Hadoop::YARN::NameNode::JMX" => 0,
  "Path::Tiny" => 0,
  "Ref::Util" => 0,
  "Scalar::Util" => 0,
  "Sub::Quote" => 0,
  "Sys::Hostname" => 0,
  "Template" => "3.102",
  "Template::App::ttree" => 0,
  "Test::More" => 0,
  "Text::Glob" => 0,
  "Text::Trim" => 0,
  "Time::Duration" => 0,
  "Time::HiRes" => 0,
  "Type::Library" => 0,
  "Type::Tiny" => 0,
  "Type::Utils" => 0,
  "Types::Standard" => 0,
  "XML::Compile::Cache" => 0,
  "XML::Compile::Util" => 0,
  "XML::LibXML" => 0,
  "XML::LibXML::Simple" => 0,
  "XML::Twig" => 0,
  "YAML::XS" => 0,
  "constant" => 0,
  "namespace::autoclean" => 0,
  "overload" => 0,
  "parent" => 0,
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
