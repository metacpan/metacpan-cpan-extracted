
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Create config files for the vr-codebase pipelines",
  "AUTHOR" => "Andrew J. Page <ap13\@sanger.ac.uk>",
  "BUILD_REQUIRES" => {
    "File::Find" => 0,
    "File::Temp" => 0,
    "Test::Most" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Bio-VertRes-Config",
  "EXE_FILES" => [
    "bin/bacteria_assembly_and_annotation",
    "bin/bacteria_assembly_single_cell",
    "bin/bacteria_mapping",
    "bin/bacteria_register_and_qc_study",
    "bin/bacteria_rna_seq_expression",
    "bin/bacteria_snp_calling",
    "bin/eukaryote_assembly",
    "bin/eukaryote_mapping",
    "bin/eukaryote_register_and_qc_study",
    "bin/eukaryote_rna_seq_expression",
    "bin/eukaryote_snp_calling",
    "bin/helminth_mapping",
    "bin/helminth_register_and_qc_study",
    "bin/helminth_rna_seq_expression",
    "bin/helminth_snp_calling",
    "bin/setup_global_configs",
    "bin/virus_assembly_and_annotation",
    "bin/virus_mapping",
    "bin/virus_register_and_qc_study",
    "bin/virus_rna_seq_expression",
    "bin/virus_snp_calling"
  ],
  "LICENSE" => "gpl",
  "NAME" => "Bio::VertRes::Config",
  "PREREQ_PM" => {
    "DBI" => 0,
    "Data::Dumper" => 0,
    "Exception::Class" => 0,
    "File::Basename" => 0,
    "File::Path" => 0,
    "File::Slurp" => 0,
    "Getopt::Long" => 0,
    "Moose" => 0,
    "Moose::Role" => 0,
    "Moose::Util::TypeConstraints" => 0
  },
  "VERSION" => "1.133090",
  "test" => {
    "TESTS" => "t/Bio/VertRes/Config/*.t t/Bio/VertRes/Config/CommandLine/*.t t/Bio/VertRes/Config/Pipelines/*.t t/Bio/VertRes/Config/Recipes/*.t t/bin/*.t"
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



