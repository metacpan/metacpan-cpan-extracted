
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "API Handle",
  "AUTHOR" => "Nour Sharabash <amirite\@cpan.org>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "API-Handle",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "API::Handle",
  "PREREQ_PM" => {
    "Carp" => 0,
    "Data::Dumper" => 0,
    "HTTP::Request" => 0,
    "JSON::XS" => 0,
    "LWP::UserAgent" => 0,
    "Moose" => 0,
    "Moose::Role" => 0,
    "Nour::Config" => 0,
    "Nour::Database" => 0,
    "Nour::Printer" => 0,
    "OX::OAuth" => 0,
    "String::CamelCase" => 0,
    "Tie::Hash::Indexed" => 0,
    "URI" => 0,
    "XML::TreePP" => 0,
    "bytes" => 0,
    "feature" => 0,
    "namespace::autoclean" => 0
  },
  "VERSION" => "0.02",
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



