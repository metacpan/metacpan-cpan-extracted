
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Take in a file of proteins and predict functions using interproscan",
  "AUTHOR" => "Andrew J. Page <ap13\@sanger.ac.uk>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Bio-InterProScanWrapper",
  "EXE_FILES" => [
    "bin/annotate_eukaryotes",
    "bin/merge_results_annotate_eukaryotes"
  ],
  "LICENSE" => "gpl",
  "NAME" => "Bio::InterProScanWrapper",
  "PREREQ_PM" => {
    "Bio::SeqIO" => 0,
    "Cwd" => 0,
    "Exception::Class" => 0,
    "File::Basename" => 0,
    "File::Copy" => 0,
    "File::Path" => 0,
    "File::Temp" => 0,
    "Getopt::Long" => 0,
    "LSF" => 0,
    "LSF::JobManager" => 0,
    "Moose" => 0
  },
  "TEST_REQUIRES" => {
    "Data::Dumper" => 0,
    "File::Slurp" => 0,
    "Moose::Role" => 0,
    "Test::Most" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "1.133090",
  "test" => {
    "TESTS" => "t/Bio/*.t t/Bio/InterProScanWrapper/*.t t/Bio/InterProScanWrapper/CommandLine/*.t t/Bio/InterProScanWrapper/External/*.t"
  }
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  my $tr = delete $WriteMakefileArgs{TEST_REQUIRES};
  my $br = $WriteMakefileArgs{BUILD_REQUIRES};
  for my $mod ( keys %$tr ) {
    if ( exists $br->{$mod} ) {
      $br->{$mod} = $tr->{$mod} if $tr->{$mod} > $br->{$mod};
    }
    else {
      $br->{$mod} = $tr->{$mod};
    }
  }
}

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



