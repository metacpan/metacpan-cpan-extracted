
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "remove clutter from your news feeds",
  "AUTHOR" => "Daniel Holz <dgholz\@gmail.com>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "App-Rssfilter",
  "EXE_FILES" => [
    "bin/rssfilter"
  ],
  "LICENSE" => "perl",
  "NAME" => "App::Rssfilter",
  "PREREQ_PM" => {
    "App::Cmd::Setup" => 0,
    "Class::Inspector" => 0,
    "Cwd" => 0,
    "HTTP::Date" => 0,
    "List::MoreUtils" => 0,
    "List::Util" => 0,
    "Log::Any" => 0,
    "Log::Any::Adapter" => 0,
    "Method::Signatures" => 0,
    "Module::Runtime" => 0,
    "Mojo::DOM" => 0,
    "Mojo::UserAgent" => 0,
    "Mojolicious" => "3.28",
    "Moo" => 0,
    "Moo::Role" => 0,
    "Path::Class" => 0,
    "Path::Class::Dir" => 0,
    "Path::Class::File" => "0.26",
    "Scalar::Util" => 0,
    "Try::Tiny" => 0,
    "YAML::XS" => 0,
    "constant" => 0,
    "experimental" => "0.005",
    "feature" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "File::Temp" => 0,
    "Mojo::Message::Response" => 0,
    "Mojo::Transaction" => 0,
    "Moose" => 0,
    "Test::Exception" => 0,
    "Test::MockObject" => 0,
    "Test::More" => 0,
    "Test::Most" => 0,
    "Test::Routine" => 0,
    "Test::Routine::Util" => 0,
    "lib" => 0,
    "namespace::autoclean" => 0
  },
  "VERSION" => "0.07",
  "test" => {
    "TESTS" => "t/*.t t/app/rssfilter/*.t t/app/rssfilter/feed/*.t t/app/rssfilter/filter/*.t t/app/rssfilter/group/*.t t/app/rssfilter/match/*.t"
  }
);


my %FallbackPrereqs = (
  "App::Cmd::Setup" => 0,
  "Class::Inspector" => 0,
  "Cwd" => 0,
  "File::Temp" => 0,
  "HTTP::Date" => 0,
  "List::MoreUtils" => 0,
  "List::Util" => 0,
  "Log::Any" => 0,
  "Log::Any::Adapter" => 0,
  "Method::Signatures" => 0,
  "Module::Runtime" => 0,
  "Mojo::DOM" => 0,
  "Mojo::Message::Response" => 0,
  "Mojo::Transaction" => 0,
  "Mojo::UserAgent" => 0,
  "Mojolicious" => "3.28",
  "Moo" => 0,
  "Moo::Role" => 0,
  "Moose" => 0,
  "Path::Class" => 0,
  "Path::Class::Dir" => 0,
  "Path::Class::File" => "0.26",
  "Scalar::Util" => 0,
  "Test::Exception" => 0,
  "Test::MockObject" => 0,
  "Test::More" => 0,
  "Test::Most" => 0,
  "Test::Routine" => 0,
  "Test::Routine::Util" => 0,
  "Try::Tiny" => 0,
  "YAML::XS" => 0,
  "constant" => 0,
  "experimental" => "0.005",
  "feature" => 0,
  "lib" => 0,
  "namespace::autoclean" => 0,
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

if ($] < 5.010) {
    $WriteMakefileArgs{PREREQ_PM} = {
        %{ $WriteMakefileArgs{PREREQ_PM} },
        "Devel::Pragma" => "0.54",
    };
}

WriteMakefile(%WriteMakefileArgs);



