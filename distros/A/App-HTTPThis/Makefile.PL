use strict;
use warnings;
use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT" => "Export the current directory over HTTP",
  "AUTHOR" => "Pedro Melo <melo\@cpan.org>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME" => "App-HTTPThis",
  "EXE_FILES" => [
    "bin/http_this"
  ],
  "LICENSE" => "artistic_2",
  "META_MERGE" => {
    "meta-spec" => { version => 2 },
    "resources" => {
      "repository" => {
        "type" => "git",
        "url" => "git://github.com/davorg-cpan/app-httpthis.git",
        "web" => "https://github.com/davorg-cpan/app-httpthis",
      },
      "bugtracker" => {
        "web" => "https://github.com/davorg-cpan/app-httpthis/issues"
      },
    },
  },
  "NAME" => "App::HTTPThis",
  "PREREQ_PM" => {
    "Config::Tiny" => 0,
    "Getopt::Long" => 0,
    "IO::Socket::INET" => 0,
    "Plack::App::DirectoryIndex" => '0.2.3',
    "Plack::Runner" => 0,
    "Pod::Usage" => 0
  },
  "TEST_REQUIRES" => {
    "File::Spec" => 0,
    "IO::Handle" => 0,
    "IPC::Open3" => 0,
    "Test::More" => 0
  },
  "VERSION_FROM" => "lib/App/HTTPThis.pm",
  "test" => {
    "TESTS" => "t/*.t"
  }
);

my %FallbackPrereqs = (
  "Config::Tiny" => 0,
  "File::Spec" => 0,
  "Getopt::Long" => 0,
  "IO::Handle" => 0,
  "IO::Socket::INET" => 0,
  "IPC::Open3" => 0,
  "Plack::App::DirectoryIndex" => '0.2.3',
  "Plack::Runner" => 0,
  "Pod::Usage" => 0,
  "Test::More" => 0
);

unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);
