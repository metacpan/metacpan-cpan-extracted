
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}

use 5.006;
use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.054

use Test::More;

plan tests => 95;

my @module_files = (
    'Bio/Roary.pm',
    'Bio/Roary/AccessoryBinaryFasta.pm',
    'Bio/Roary/AccessoryClustering.pm',
    'Bio/Roary/AnalyseGroups.pm',
    'Bio/Roary/AnnotateGroups.pm',
    'Bio/Roary/AssemblyStatistics.pm',
    'Bio/Roary/BedFromGFFRole.pm',
    'Bio/Roary/ChunkFastaFile.pm',
    'Bio/Roary/ClustersRole.pm',
    'Bio/Roary/CombinedProteome.pm',
    'Bio/Roary/CommandLine/AssemblyStatistics.pm',
    'Bio/Roary/CommandLine/Common.pm',
    'Bio/Roary/CommandLine/CreatePanGenome.pm',
    'Bio/Roary/CommandLine/ExtractProteomeFromGff.pm',
    'Bio/Roary/CommandLine/GeneAlignmentFromNucleotides.pm',
    'Bio/Roary/CommandLine/IterativeCdhit.pm',
    'Bio/Roary/CommandLine/ParallelAllAgainstAllBlastp.pm',
    'Bio/Roary/CommandLine/QueryRoary.pm',
    'Bio/Roary/CommandLine/Roary.pm',
    'Bio/Roary/CommandLine/RoaryCoreAlignment.pm',
    'Bio/Roary/CommandLine/RoaryPostAnalysis.pm',
    'Bio/Roary/CommandLine/RoaryReorderSpreadsheet.pm',
    'Bio/Roary/CommandLine/TransferAnnotationToGroups.pm',
    'Bio/Roary/CommandLine/UniqueGenesPerSample.pm',
    'Bio/Roary/ContigsToGeneIDsFromGFF.pm',
    'Bio/Roary/Exceptions.pm',
    'Bio/Roary/External/Blastp.pm',
    'Bio/Roary/External/Cdhit.pm',
    'Bio/Roary/External/CheckTools.pm',
    'Bio/Roary/External/Fasttree.pm',
    'Bio/Roary/External/GeneAlignmentFromNucleotides.pm',
    'Bio/Roary/External/IterativeCdhit.pm',
    'Bio/Roary/External/Mafft.pm',
    'Bio/Roary/External/Makeblastdb.pm',
    'Bio/Roary/External/Mcl.pm',
    'Bio/Roary/External/PostAnalysis.pm',
    'Bio/Roary/External/Prank.pm',
    'Bio/Roary/ExtractCoreGenesFromSpreadsheet.pm',
    'Bio/Roary/ExtractProteomeFromGFF.pm',
    'Bio/Roary/ExtractProteomeFromGFFs.pm',
    'Bio/Roary/FilterFullClusters.pm',
    'Bio/Roary/FilterUnknownsFromFasta.pm',
    'Bio/Roary/GeneNamesFromGFF.pm',
    'Bio/Roary/GroupLabels.pm',
    'Bio/Roary/GroupStatistics.pm',
    'Bio/Roary/InflateClusters.pm',
    'Bio/Roary/IterativeCdhit.pm',
    'Bio/Roary/JobRunner/Local.pm',
    'Bio/Roary/JobRunner/Parallel.pm',
    'Bio/Roary/JobRunner/Role.pm',
    'Bio/Roary/LookupGeneFiles.pm',
    'Bio/Roary/MergeMultifastaAlignments.pm',
    'Bio/Roary/OrderGenes.pm',
    'Bio/Roary/Output/BlastIdentityFrequency.pm',
    'Bio/Roary/Output/CoreGeneAlignmentCoordinatesEMBL.pm',
    'Bio/Roary/Output/DifferenceBetweenSets.pm',
    'Bio/Roary/Output/EMBLHeaderCommon.pm',
    'Bio/Roary/Output/EmblGroups.pm',
    'Bio/Roary/Output/GroupMultifasta.pm',
    'Bio/Roary/Output/GroupsMultifastaNucleotide.pm',
    'Bio/Roary/Output/GroupsMultifastaProtein.pm',
    'Bio/Roary/Output/GroupsMultifastas.pm',
    'Bio/Roary/Output/GroupsMultifastasNucleotide.pm',
    'Bio/Roary/Output/NumberOfGroups.pm',
    'Bio/Roary/Output/QueryGroups.pm',
    'Bio/Roary/ParallelAllAgainstAllBlast.pm',
    'Bio/Roary/ParseGFFAnnotationRole.pm',
    'Bio/Roary/PostAnalysis.pm',
    'Bio/Roary/PrepareInputFiles.pm',
    'Bio/Roary/PresenceAbsenceMatrix.pm',
    'Bio/Roary/QC/Report.pm',
    'Bio/Roary/ReformatInputGFFs.pm',
    'Bio/Roary/ReorderSpreadsheet.pm',
    'Bio/Roary/SampleOrder.pm',
    'Bio/Roary/SequenceLengths.pm',
    'Bio/Roary/SortFasta.pm',
    'Bio/Roary/SplitGroups.pm',
    'Bio/Roary/SpreadsheetRole.pm',
    'Bio/Roary/UniqueGenesPerSample.pm'
);

my @scripts = (
    'bin/create_pan_genome',
    'bin/extract_proteome_from_gff',
    'bin/iterative_cdhit',
    'bin/pan_genome_assembly_statistics',
    'bin/pan_genome_core_alignment',
    'bin/pan_genome_post_analysis',
    'bin/pan_genome_reorder_spreadsheet',
    'bin/parallel_all_against_all_blastp',
    'bin/protein_alignment_from_nucleotides',
    'bin/query_pan_genome',
    'bin/roary',
    'bin/roary-pan_genome_reorder_spreadsheet',
    'bin/roary-query_pan_genome',
    'bin/roary-unique_genes_per_sample',
    'bin/transfer_annotation_to_groups'
);

# no fake home requested

my $inc_switch = -d 'blib' ? '-Mblib' : '-Ilib';

use File::Spec;
use IPC::Open3;
use IO::Handle;

open my $stdin, '<', File::Spec->devnull or die "can't open devnull: $!";

my @warnings;
for my $lib (@module_files)
{
    # see L<perlfaq8/How can I capture STDERR from an external command?>
    my $stderr = IO::Handle->new;

    my $pid = open3($stdin, '>&STDERR', $stderr, $^X, $inc_switch, '-e', "require q[$lib]");
    binmode $stderr, ':crlf' if $^O eq 'MSWin32';
    my @_warnings = <$stderr>;
    waitpid($pid, 0);
    is($?, 0, "$lib loaded ok");

    shift @_warnings if @_warnings and $_warnings[0] =~ /^Using .*\bblib/
        and not eval { require blib; blib->VERSION('1.01') };

    if (@_warnings)
    {
        warn @_warnings;
        push @warnings, @_warnings;
    }
}

foreach my $file (@scripts)
{ SKIP: {
    open my $fh, '<', $file or warn("Unable to open $file: $!"), next;
    my $line = <$fh>;

    close $fh and skip("$file isn't perl", 1) unless $line =~ /^#!\s*(?:\S*perl\S*)((?:\s+-\w*)*)(?:\s*#.*)?$/;
    my @flags = $1 ? split(' ', $1) : ();

    my $stderr = IO::Handle->new;

    my $pid = open3($stdin, '>&STDERR', $stderr, $^X, $inc_switch, @flags, '-c', $file);
    binmode $stderr, ':crlf' if $^O eq 'MSWin32';
    my @_warnings = <$stderr>;
    waitpid($pid, 0);
    is($?, 0, "$file compiled ok");

    shift @_warnings if @_warnings and $_warnings[0] =~ /^Using .*\bblib/
        and not eval { require blib; blib->VERSION('1.01') };

    # in older perls, -c output is simply the file portion of the path being tested
    if (@_warnings = grep { !/\bsyntax OK$/ }
        grep { chomp; $_ ne (File::Spec->splitpath($file))[2] } @_warnings)
    {
        warn @_warnings;
        push @warnings, @_warnings;
    }
} }



is(scalar(@warnings), 0, 'no warnings found')
    or diag 'got warnings: ', ( Test::More->can('explain') ? Test::More::explain(\@warnings) : join("\n", '', @warnings) );
