
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "concatenate and print JSON files",
  "AUTHOR" => "Rocco Caputo <rcaputo\@cpan.org>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "App-PipeFilter",
  "EXE_FILES" => [
    "bin/jcat",
    "bin/jcut",
    "bin/jeth2ip",
    "bin/jip2udp",
    "bin/jmap",
    "bin/jpcap2eth",
    "bin/json2pcap",
    "bin/json2tsv",
    "bin/json2yaml",
    "bin/jsonpath",
    "bin/jsort",
    "bin/mysql2json",
    "bin/pcap2json"
  ],
  "LICENSE" => "perl",
  "NAME" => "App::PipeFilter",
  "PREREQ_PM" => {
    "JSON::Path" => 0,
    "JSON::XS" => 0,
    "Moose" => 0,
    "MooseX::Getopt" => 0,
    "YAML::Any" => 0
  },
  "VERSION" => "0.005",
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



