
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Populate a mirror with a list of distributions",
  "AUTHOR" => "Peter Shangov <pshangov\@yahoo.com>",
  "BUILD_REQUIRES" => {
    "CPAN::Faker::HTTPD" => 0,
    "File::Copy" => 0,
    "File::Find" => 0,
    "Module::Faker::Dist" => 0,
    "Moose::Meta::Class" => 0,
    "Test::More" => 0,
    "Test::Most" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "CPAN-Local-Plugin-DistroList",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "CPAN::Local::Plugin::DistroList",
  "PREREQ_PM" => {
    "CPAN::DistnameInfo" => 0,
    "CPAN::Local::Plugin" => 0,
    "CPAN::Local::Role::Gather" => 0,
    "File::Temp" => 0,
    "LWP::Simple" => 0,
    "Moose" => 0,
    "Path::Class" => 0,
    "Try::Tiny" => 0,
    "URI" => 0,
    "namespace::clean" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.003",
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



