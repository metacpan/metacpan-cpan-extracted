
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Read and write CPAN index files",
  "AUTHOR" => "Peter Shangov <pshangov\@yahoo.com>",
  "BUILD_REQUIRES" => {
    "File::Find" => 0,
    "Test::More" => 0,
    "Test::Most" => 0,
    "Test::XML" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "CPAN-Index-API",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "CPAN::Index::API",
  "PREREQ_PM" => {
    "Carp" => 0,
    "Class::Load" => 0,
    "Compress::Zlib" => 0,
    "File::Basename" => 0,
    "File::Slurp" => 0,
    "File::Temp" => 0,
    "LWP::Simple" => 0,
    "List::Util" => 0,
    "Moose" => 0,
    "Moose::Role" => 0,
    "Moose::Util::TypeConstraints" => 0,
    "MooseX::ClassAttribute" => 0,
    "Path::Class" => 0,
    "Scalar::Util" => 0,
    "Symbol" => 0,
    "Text::Template" => 0,
    "URI" => 0,
    "URI::file" => 0,
    "XML::Twig" => 0,
    "namespace::autoclean" => 0,
    "namespace::clean" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.007",
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



