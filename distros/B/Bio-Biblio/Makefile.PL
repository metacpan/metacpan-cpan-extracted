
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Modules to access bibliographics repositories and handle citation files.",
  "AUTHOR" => "BioPerl Team <bioperl-l\@bioperl.org>",
  "BUILD_REQUIRES" => {
    "File::Find" => 0,
    "File::Spec" => 0,
    "File::Temp" => 0,
    "Test::More" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Bio-Biblio",
  "EXE_FILES" => [
    "bin/bp_biblio"
  ],
  "LICENSE" => "perl",
  "NAME" => "Bio::Biblio",
  "PREREQ_PM" => {
    "Bio::Annotation::DBLink" => 0,
    "Bio::DB::DBFetch" => 0,
    "Bio::Root::IO" => 0,
    "Bio::Root::Root" => 0,
    "Bio::Root::RootI" => 0,
    "Data::Dumper" => 0,
    "Getopt::Std" => 0,
    "LWP::Simple" => 0,
    "SOAP::Lite" => 0,
    "Symbol" => 0,
    "URI::Escape" => 0,
    "XML::Parser" => 0,
    "XML::Twig" => 0,
    "parent" => 0,
    "strict" => 0,
    "utf8" => 0,
    "vars" => 0,
    "warnings" => 0
  },
  "VERSION" => "1.70",
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



