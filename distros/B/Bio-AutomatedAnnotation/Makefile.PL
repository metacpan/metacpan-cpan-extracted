
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Automated annotation of assemblies",
  "AUTHOR" => "Andrew J. Page <ap13\@sanger.ac.uk>",
  "BUILD_REQUIRES" => {
    "Data::Dumper" => 0,
    "Env::Path" => 0,
    "File::Find" => 0,
    "File::Slurp" => 0,
    "Moose::Role" => 0,
    "Test::Most" => 0,
    "strict" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Bio-AutomatedAnnotation",
  "EXE_FILES" => [
    "bin/annotate_bacteria",
    "bin/gene_name_occurances",
    "bin/parse_genes_from_gffs"
  ],
  "LICENSE" => "gpl",
  "NAME" => "Bio::AutomatedAnnotation",
  "PREREQ_PM" => {
    "Bio::Perl" => 0,
    "Bio::PrimarySeq" => 0,
    "Bio::SearchIO" => 0,
    "Bio::Seq" => 0,
    "Bio::SeqFeature::Generic" => 0,
    "Bio::SeqIO" => 0,
    "Bio::Tools::GFF" => 0,
    "Cwd" => 0,
    "Exception::Class" => 0,
    "File::Basename" => 0,
    "File::Copy" => 0,
    "File::Temp" => 0,
    "FindBin" => 0,
    "Getopt::Long" => 0,
    "List::Util" => 0,
    "Moose" => 0,
    "POSIX" => 0,
    "Scalar::Util" => 0,
    "Text::CSV" => 0,
    "Time::Piece" => 0,
    "Time::Seconds" => 0,
    "XML::Simple" => 0,
    "warnings" => 0
  },
  "VERSION" => "1.133090",
  "test" => {
    "TESTS" => "t/*.t t/Bio/*.t t/Bio/AutomatedAnnotation/*.t t/Bio/AutomatedAnnotation/CommandLine/*.t t/Bio/AutomatedAnnotation/External/*.t"
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



