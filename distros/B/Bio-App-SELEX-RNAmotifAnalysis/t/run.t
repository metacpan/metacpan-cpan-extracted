#!/usr/bin/env perl
use 5.008;      # Require at least Perl version 5.08
use strict;     # Must declare all variables before using them use warnings;   # Emit helpful warnings
use autodie;    # Automatically throw fatal exceptions for common unrecoverable
                #   errors (e.g. trying to open a non-existent file)

use Test::More;                  # Testing module
use Test::LongString;            # Compare strings byte by byte
use File::Temp  qw( tempfile );  #
use Data::Section -setup;        # Have various DATA sections, allows for mock files
use File::Slurp qw( slurp);

use lib 'lib';              # add 'lib' to @INC
use Bio::App::SELEX::RNAmotifAnalysis;  # 

my $DELETE_TEMP_FILES = 1;


{    # Non-author user tests 
    my $file = filename_for('sequences');
    system("perl lib/Bio/App/SELEX/RNAmotifAnalysis.pm --simple $file ");
    my $batch_num = 1;
    for my $batch_num (1 .. 4){
        my $batch_filename  = "batch_$batch_num";
        my $batch_dir       = "$batch_filename.dir/";
        my $expected        = string_from( 'expected_script' . $batch_num );
        my $result          = slurp( $batch_dir . $batch_filename );
        is_string( $result, $expected, "'$batch_filename' okay" );
        $batch_num++;
    }
    delete_generated_files() if $DELETE_TEMP_FILES;
}

{    # Non-author user tests 
    my $file = filename_for('fastq');
    system("perl lib/Bio/App/SELEX/RNAmotifAnalysis.pm --fastq $file ");
    my $batch_num = 1;
    for my $batch_num (1 .. 4){
        my $batch_filename  = "batch_$batch_num";
        my $batch_dir       = "$batch_filename.dir/";
        my $expected        = string_from( 'expected_script' . $batch_num );
        my $result          = slurp( $batch_dir . $batch_filename );
        is_string( $result, $expected, "'$batch_filename' okay" );
        $batch_num++;
    }
    delete_generated_files() if $DELETE_TEMP_FILES;
}


SKIP: {    # AUTHOR TESTS

    my $developer_tests; 

    if(defined $ENV{RUN_DEVELOPER_TESTS}){
        $developer_tests = $ENV{RUN_DEVELOPER_TESTS};
    }else{
        $developer_tests = 0;
    }

    skip 'AUTHOR TESTS', 54 if ! $developer_tests;
    my $seq_file = filename_for('sequences');
    system("bin/RNAmotifAnalysis --simple $seq_file --run &> /dev/null");
    my $batch_num = 1;
    for my $batch_num (1 .. 4){
        my $batch_filename  = "batch_$batch_num";
        my $batch_dir       = "$batch_filename.dir/";
        my $expected        = string_from( 'expected_script' . $batch_num );
        my $result          = slurp( $batch_dir . $batch_filename );
        is_string( $result, $expected, "AUTHOR TEST: '$batch_filename' okay" );
        $batch_num++;
    }

    sleep 30;

    $batch_num = 1;
    for my $base_name ( map( "cluster_${_}_top", 1 .. 3 ), 'single_4_top' ) {
        my $batch_filename  = "batch_$batch_num";
        my $batch_dir       = "$batch_filename.dir";
        chdir $batch_dir;
        my $result_filename = $base_name . '.sto';
        my $expected = string_from( 'expected_' . $result_filename );
        my $result   = slurp( $result_filename );
        is_string( $result, $expected, "AUTHOR TEST: '$base_name' okay" );
        chdir '..';
        $batch_num++;
    }
    delete_generated_files() if $DELETE_TEMP_FILES;
}

done_testing();

sub delete_generated_files {
    delete_temp_file('clusters.txt');
    delete_temp_file('cluster.cfg');
    my @files_to_delete = glob '*_top.fasta';
    delete_temp_file($_) for @files_to_delete;
    my @dirs_to_delete = glob 'batch*.dir';
    delete_temp_dir($_) for @dirs_to_delete; 
}

sub scrub_directories {
   my $file_string = shift; 
   my $DIR = qr| ((?: / [^/]*?){1,} / ) |xms;

    open(my $fh, '<', \$file_string);
    open(my $fh_out, '>', \my $file_string_out);

    while(my $line = readline $fh){
        chomp $line;
        if($line =~ $DIR ){
            $line =~ s{$DIR}{/dummy/path/to/};
        }
        print {$fh_out} $line, "\n";
    }

    return $file_string_out;
}

sub filename_for {
    my $section           = shift;
    my ( $fh, $filename ) = tempfile();
    my $string            = string_from($section);
    print {$fh} $string;
    close $fh;
    return $filename;
}

sub temp_filename {
    my ($fh, $filename) = tempfile();
    close $fh;
    return $filename;
}

sub delete_temp_file {
    my $filename = shift;
    my $result = unlink $filename;
    ok($result, "successfully deleted temporary file '$filename'");
}

sub delete_temp_dir {
    my $dirname = shift;
    my $result = system("rm -rf $dirname");
    is($result,0, "successfully deleted temporary dir '$dirname'");
}


sub sref_from {
    my $section = shift;

    #Scalar reference from the section
    return __PACKAGE__->section_data($section);
}

sub string_from {
    my $section = shift;

    #Get the scalar reference
    my $sref = sref_from($section);

    #Return the actual scalar (probably a string), not the reference to it
    return ${$sref};
}

__DATA__
__[ config ]__
[Flags_for]
RNAalifold=-r -cv 0.6 -nc 10 -p -d2 -noLP -color -aln
mafft=--preservecase --clustalout

[executables]
CreateStockholm=clustal2stockholm.pl
RNAalifold=RNAalifold
cmalign=cmalign
cmbuild=cmbuild
cmcalibrate=cmcalibrate
cmsearch=cmsearch
mafft=mafft
stock2fasta=stock2fasta.pl

__[ sequences ]__
AGCGCGGCACCCAAAATCGAAATCCGAAGCGAACGGGAGAATGCGACCAAAGTAACCCTGTGAATGGC
TGAAAATGCAGACCAAGAAAATCCGAGGTGATAAACGGGAAAACACAAAGAAACACATAACGTTGCAAGTC
TGCTAAACCAAGTAAGAATCCGTGAAGTCACAGCACGGGATAAAACTGTGTCAAAACGCCATAGCT
TGAACAAACGCGATGAACATTAGGCTATCCTCAGGCGGAGAGGGACAAAACGCACTTATCCCTAAGGC
TGAACAAACGCGATGAACATTAGGCTATCCTCAGGCGGAGAGGGACAAAACGCACTTATCCCTAAGGC
TGCTAAACCAAGTAAGAATCCGTGAAGTCACAGCACGGGATAAAACTGTGTCAAAACGCCATAGCT
AGCGCGGCACCCAAAATCGAAATCCGAAGGCGAACGGGAGAATGCGACCAAAGATACCCTGTGAATGGC
TGCTAAACCAAGTAAGAATCCGTGAAGTCACAGCACGGGATAAAACTGTGTCAAAACGCCATAGCT
AGTGCGGTACCCAAAATCGAAATCCGAAGGTGAACGGGAGAATGCGACCAAAGATACCCTGTGAATGGC
TGAAAATGCAGACCAAGAAAATCCGAGGTGATAAACGGGAAAACACAAAGAAACAATAACGTTGCAAGTC
TGAACAAACGCGATGAACATTAGGCTATCCTCAGGCGGAGAGGGACAAAACGCACTTATCCCTAAGGC
TGAAAATGCAGACCAAGAAAATCCGAGGTGATAAACGGGAAAACACAAAGAAACACATAACGTTGCAAGTC

AGCGCGGCACCCAAAATCGAAATCCGAAGGCGAACGGGAGAATGCGACCAAAGATACCCTGTGAATGGC
TGAAAATGCAGACCAAGAAAATCCGAGGTGATAAACGGGAAAACACGAAGAAACTATAACGTTGCAAGTC
TGAACAAACGCGATGAACACTAGGCTATCCTCAGGCGGAGAGGGACAAAACGCACTTATCCCTAAGGCAC
__[ fastq ]__
@HWI-ST538_0098:5:1:15686:1997#CAGATC/1
AGCGCGGCACCCAAAATCGAAATCCGAAGCGAACGGGAGAATGCGACCAAAGTAACCCTGTGAATGGC
+
ggggggggggggggggfgggggfgggggggggcgegggggdddddBacb``a```ggggggggggggg
@HWI-ST538_0098:5:1:16289:1996#CAGATC/1
TGAAAATGCAGACCAAGAAAATCCGAGGTGATAAACGGGAAAACACAAAGAAACACATAACGTTGCAAGTC
+
f__gacece\cbegdbfZdbdb_ebg_gaebcdaW`_``WY`^\`B_`abcc\cba\ab\deed_cfeZ\c
@HWI-ST538_0098:5:1:17279:1993#CAGATC/1
TGCTAAACCAAGTAAGAATCCGTGAAGTCACAGCACGGGATAAAACTGTGTCAAAACGCCATAGCT
+
YSSUB]]Y][aadd_eeee\R\_\ZN\]_Zbc_BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
@HWI-ST538_0098:5:1:1498:2038#CAGATC/1
TGAACAAACGCGATGAACATTAGGCTATCCTCAGGCGGAGAGGGACAAAACGCACTTATCCCTAAGGC
+
eee`ddccddefefffefeffffffffffe`eeffeffedMcd`c_d\_dffebee\aeeefadceec
@HWI-ST538_0098:5:1:1498:2038#CAGATC/1
TGAACAAACGCGATGAACATTAGGCTATCCTCAGGCGGAGAGGGACAAAACGCACTTATCCCTAAGGC
+
eee`ddccddefefffefeffffffffffe`eeffeffedMcd`c_d\_dffebee\aeeefadceec
@HWI-ST538_0098:5:1:17279:1993#CAGATC/1
TGCTAAACCAAGTAAGAATCCGTGAAGTCACAGCACGGGATAAAACTGTGTCAAAACGCCATAGCT
+
YSSUB]]Y][aadd_eeee\R\_\ZN\]_Zbc_BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
@HWI-ST538_0098:5:1:15686:1997#CAGATC/1
AGCGCGGCACCCAAAATCGAAATCCGAAGGCGAACGGGAGAATGCGACCAAAGATACCCTGTGAATGGC
+
ggggggggggfggggggfgggggfgggggggggcgegggggdddddBacb``a```ggggggggggggg
@HWI-ST538_0098:5:1:17279:1993#CAGATC/1
TGCTAAACCAAGTAAGAATCCGTGAAGTCACAGCACGGGATAAAACTGTGTCAAAACGCCATAGCT
+
YSSUB]]Y][aadd_eeee\R\_\ZN\]_Zbc_BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
@HWI-ST538_0098:5:1:17686:1997#CAGATC/1
AGTGCGGTACCCAAAATCGAAATCCGAAGGTGAACGGGAGAATGCGACCAAAGATACCCTGTGAATGGC
+
ggggggggggfggggggfgggggfgggggggggcgegggggdddddBacb``a```ggggggggggggg
@HWI-ST538_0128:5:1:17686:1997#CAGATC/1
TGAAAATGCAGACCAAGAAAATCCGAGGTGATAAACGGGAAAACACAAAGAAACAATAACGTTGCAAGTC
+
ggggggggggfggggggfgggggfggggggggBgcgegggggdddddBacb``a```ggggggggggggg
@HWI-ST538_0098:5:1:1498:2038#CAGATC/1
TGAACAAACGCGATGAACATTAGGCTATCCTCAGGCGGAGAGGGACAAAACGCACTTATCCCTAAGGC
+
eee`ddccddefefffefeffffffffffe`eeffeffedMcd`c_d\_dffebee\aeeefadceec
@HWI-ST538_0098:5:1:16289:1996#CAGATC/1
TGAAAATGCAGACCAAGAAAATCCGAGGTGATAAACGGGAAAACACAAAGAAACACATAACGTTGCAAGTC
+
f__gacece\cbegdbfZdbdb_ebg_gaebcdaW`_``WY`^\`B_`abcc\cba\ab\deed_cfeZ\c
@HWI-ST538_0098:5:1:15686:1997#CAGATC/1
AGCGCGGCACCCAAAATCGAAATCCGAAGGCGAACGGGAGAATGCGACCAAAGATACCCTGTGAATGGC
+
ggggggggggfggggggfgggggfgggggggggcgegggggdddddBacb``a```ggggggggggggg
@HWI-ST538_1098:5:1:15186:1917#CAGATC/1
TGAAAATGCAGACCAAGAAAATCCGAGGTGATAAACGGGAAAACACGAAGAAACTATAACGTTGCAAGTC
+
ggggBggggggfggggggfgggggfgggggggggcgegggggdddddBacb``a```ggggggggggggg
@HWI-ST538_1098:5:1:15186:1917#CAGATC/1
TGAACAAACGCGATGAACACTAGGCTATCCTCAGGCGGAGAGGGACAAAACGCACTTATCCCTAAGGCAC
+
ggggBggggggfggggggfgggggfgggggggggcgegggggdddddBacb``a```ggggggggggggg
__[ expected_cluster_1_top.sto ]__
# STOCKHOLM 1.0
#=GC SS_cons .........((((((..(....)..))))...........(((((.((.......)).)))))...)
     1.1.3   TGAACAAACGCGATGAACATTAGGCTATCCTCAGGCGGAGAGGGACAAAACGCACTTATCCCTAAGG
     1.2.1   TGAACAAACGCGATGAACACTAGGCTATCCTCAGGCGGAGAGGGACAAAACGCACTTATCCCTAAGG

#=GC SS_cons )..
     1.1.3   C--
     1.2.1   CAC

//
__[ expected_cluster_2_top.sto ]__
# STOCKHOLM 1.0
#=GC SS_cons ......(((.......................................................)))
     2.1.2   TGAAAATGCAGACCAAGAAAATCCGAGGTGATAAACGGGAAAACACAAAGAAACACATAACGTTGCA
     2.2.1   TGAAAATGCAGACCAAGAAAATCCGAGGTGATAAACGGGAAAACACAAAGAAACA-ATAACGTTGCA
     2.3.1   TGAAAATGCAGACCAAGAAAATCCGAGGTGATAAACGGGAAAACACGAAGAAACT-ATAACGTTGCA

#=GC SS_cons ....
     2.1.2   AGTC
     2.2.1   AGTC
     2.3.1   AGTC

//
__[ expected_cluster_3_top.sto ]__
# STOCKHOLM 1.0
#=GC SS_cons ..((((...(((....(((.....)))..(....))))....)))).(((.((.....)).....))
     3.1.2   AGCGCGGCACCCAAAATCGAAATCCGAAGGCGAACGGGAGAATGCGACCAAAGATACCCTGTGAATG
     3.2.1   AGCGCGGCACCCAAAATCGAAATCCGAA-GCGAACGGGAGAATGCGACCAAAGTAACCCTGTGAATG
     3.3.1   AGTGCGGTACCCAAAATCGAAATCCGAAGGTGAACGGGAGAATGCGACCAAAGATACCCTGTGAATG

#=GC SS_cons ).
     3.1.2   GC
     3.2.1   GC
     3.3.1   GC

//
__[ expected_single_4_top.sto ]__
# STOCKHOLM 1.0
#=GC SS_cons .((((.....(((.....((((((.........)))))).....)))((((....))))..)))).
     4.1.3   TGCTAAACCAAGTAAGAATCCGTGAAGTCACAGCACGGGATAAAACTGTGTCAAAACGCCATAGCT
     4.1.3b  TGCTAAACCAAGTAAGAATCCGTGAAGTCACAGCACGGGATAAAACTGTGTCAAAACGCCATAGCT

//
__[ expected_script1 ]__
mv ../cluster_1_top.fasta .
mafft --preservecase --clustalout cluster_1_top.fasta > cluster_1_top.aln
RNAalifold -r -cv 0.6 -nc 10 -p -d2 -noLP -color -aln < cluster_1_top.aln > cluster_1_top.gc
mv alirna.ps cluster_1_top_alirna.ps
mv alidot.ps cluster_1_top_alidot.ps
mv aln.ps cluster_1_top_aln.ps
mv alifold.out cluster_1_top_alifold.out
selex_clustal2stockholm.pl cluster_1_top.aln cluster_1_top.gc > cluster_1_top.sto
cmbuild cluster_1_top.cm cluster_1_top.sto
__[ expected_script2 ]__
mv ../cluster_2_top.fasta .
mafft --preservecase --clustalout cluster_2_top.fasta > cluster_2_top.aln
RNAalifold -r -cv 0.6 -nc 10 -p -d2 -noLP -color -aln < cluster_2_top.aln > cluster_2_top.gc
mv alirna.ps cluster_2_top_alirna.ps
mv alidot.ps cluster_2_top_alidot.ps
mv aln.ps cluster_2_top_aln.ps
mv alifold.out cluster_2_top_alifold.out
selex_clustal2stockholm.pl cluster_2_top.aln cluster_2_top.gc > cluster_2_top.sto
cmbuild cluster_2_top.cm cluster_2_top.sto
__[ expected_script3 ]__
mv ../cluster_3_top.fasta .
mafft --preservecase --clustalout cluster_3_top.fasta > cluster_3_top.aln
RNAalifold -r -cv 0.6 -nc 10 -p -d2 -noLP -color -aln < cluster_3_top.aln > cluster_3_top.gc
mv alirna.ps cluster_3_top_alirna.ps
mv alidot.ps cluster_3_top_alidot.ps
mv aln.ps cluster_3_top_aln.ps
mv alifold.out cluster_3_top_alifold.out
selex_clustal2stockholm.pl cluster_3_top.aln cluster_3_top.gc > cluster_3_top.sto
cmbuild cluster_3_top.cm cluster_3_top.sto
__[ expected_script4 ]__
mv ../single_4_top.fasta .
mafft --preservecase --clustalout single_4_top.fasta > single_4_top.aln
RNAalifold -r -cv 0.6 -nc 10 -p -d2 -noLP -color -aln < single_4_top.aln > single_4_top.gc
mv alirna.ps single_4_top_alirna.ps
mv alidot.ps single_4_top_alidot.ps
mv aln.ps single_4_top_aln.ps
mv alifold.out single_4_top_alifold.out
selex_clustal2stockholm.pl single_4_top.aln single_4_top.gc > single_4_top.sto
cmbuild single_4_top.cm single_4_top.sto
