
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Comparative assesment of variant calling (CAVar)",
  "AUTHOR" => "Andrew J. Page <ap13\@sanger.ac.uk>",
  "BUILD_REQUIRES" => {
    "Env::Path" => 0,
    "Test::Most" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Bio-Pipeline-Comparison",
  "EXE_FILES" => [
    "bin/evaluate_pipeline",
    "bin/evolve_genome",
    "bin/vcf-compare"
  ],
  "LICENSE" => "gpl",
  "NAME" => "Bio::Pipeline::Comparison",
  "PREREQ_PM" => {
    "Archive::Tar" => 0,
    "Bio::SeqIO" => 0,
    "Carp" => 0,
    "Cwd" => 0,
    "Data::Dumper" => 0,
    "Exception::Class" => 0,
    "Exporter" => 0,
    "File::Basename" => 0,
    "File::Copy" => 0,
    "File::Find" => 0,
    "File::Path" => 0,
    "File::Temp" => 0,
    "File::Which" => 0,
    "Getopt::Long" => 0,
    "IO::Zlib" => 0,
    "Moose" => 0,
    "Moose::Util::TypeConstraints" => 0,
    "POSIX" => 0,
    "Try::Tiny" => 0,
    "Vcf4_0" => 0,
    "VcfReader" => 0,
    "base" => 0,
    "strict" => 0,
    "vars" => 0,
    "warnings" => 0
  },
  "VERSION" => "1.123050",
  "test" => {
    "TESTS" => "t/*.t t/Bio/Pipeline/Comparison/Generate/*.t t/Bio/Pipeline/Comparison/Report/*.t"
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



