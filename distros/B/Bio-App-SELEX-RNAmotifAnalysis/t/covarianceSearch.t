#!/usr/bin/env perl
use 5.008;      # Require at least Perl version 5.8
use strict;     # Must declare all variables before using them
use warnings;   # Emit helpful warnings
use autodie;    # Fatal exceptions for common unrecoverable errors (e.g. w/open)

# Testing-related modules
use Test::More;                    # provide testing functions (e.g. is, like)
use Test::LongString;              # Compare strings byte by byte
use Data::Section -setup;          # Set up labeled DATA sections
use File::Temp qw( tempfile );     #
use File::Slurp qw( slurp    );    # Read a file into a string

use Carp qw( croak );
# Distribution-specific modules
use lib 'lib';                     # add 'lib' to @INC

{
    my $output_filename = temp_filename();
    my $config_filename = filename_for('config');
    system( "perl lib/Bio/App/SELEX/selex_covarianceSearch --config $config_filename --cm test.cm --sto search.sto --rounds 10 --fasta search.fasta > $output_filename");
    my $result   = slurp $output_filename;
    my $expected = string_from('expected');
    is_string( $result, $expected, 'Successfully created script file' );
}

done_testing();

sub sref_from {
    my $section = shift;

    #Scalar reference to the section text
    return __PACKAGE__->section_data($section);
}

sub string_from {
    my $section = shift;

    #Get the scalar reference
    my $sref = sref_from($section);

    #Return a string containing the entire section
    return ${$sref};
}

sub fh_from {
    my $section = shift;
    my $sref    = sref_from($section);

    #Create filehandle to the referenced scalar
    open( my $fh, '<', $sref );
    return $fh;
}

sub assign_filename_for {
    my $filename = shift;
    my $section  = shift;

    # Don't overwrite existing file
    croak "'$filename' already exists." if -e $filename;

    my $string = string_from($section);
    open( my $fh, '>', $filename );
    print {$fh} $string;
    close $fh;
    return;
}

sub filename_for {
    my $section = shift;
    my ( $fh, $filename ) = tempfile();
    my $string = string_from($section);
    print {$fh} $string;
    close $fh;
    return $filename;
}

sub temp_filename {
    my ( $fh, $filename ) = tempfile();
    close $fh;
    return $filename;
}

sub delete_temp_file {
    my $filename  = shift;
    my $delete_ok = unlink $filename;
    ok( $delete_ok, "deleted temp file '$filename'" );
}

#------------------------------------------------------------------------
# IMPORTANT!
#
# Each line from each section automatically ends with a newline character
#------------------------------------------------------------------------

__DATA__
__[ expected ]__
#round1
/share/apps/bin/cmcalibrate test.cm
/share/apps/bin/cmsearch --toponly -E 0.1 --tabfile test_rnd1.tab test.cm search.fasta

awk '$1!~/^#/{print $2}' test_rnd1.tab > test_rnd1_clusters_found.txt

grep -w -f test_rnd1_clusters_found.txt search.sto > test_rnd2.sto
perl /home/user/perl5/lib/perl5/Bio/App/SELEX/stock2fasta.pl test_rnd2.sto > test_rnd2.fasta


#round2
/share/apps/bin/cmalign -o test_rnd2_cmaligned.sto test.cm test_rnd2.fasta
/share/apps/bin/cmbuild test_rnd2_aln.cm test_rnd2_cmaligned.sto
/share/apps/bin/cmcalibrate test_rnd2_aln.cm
/share/apps/bin/cmsearch --toponly -E 0.1 --tabfile test_rnd2.tab test_rnd2_aln.cm search.fasta

awk '$1!~/^#/{print $2}' test_rnd2.tab > test_rnd2_clusters_found.txt

grep -w -f test_rnd2_clusters_found.txt search.sto > test_rnd3.sto
perl /home/user/perl5/lib/perl5/Bio/App/SELEX/stock2fasta.pl test_rnd3.sto > test_rnd3.fasta


#round3
/share/apps/bin/cmalign -o test_rnd3_cmaligned.sto test.cm test_rnd3.fasta
/share/apps/bin/cmbuild test_rnd3_aln.cm test_rnd3_cmaligned.sto
/share/apps/bin/cmcalibrate test_rnd3_aln.cm
/share/apps/bin/cmsearch --toponly -E 0.1 --tabfile test_rnd3.tab test_rnd3_aln.cm search.fasta

awk '$1!~/^#/{print $2}' test_rnd3.tab > test_rnd3_clusters_found.txt

grep -w -f test_rnd3_clusters_found.txt search.sto > test_rnd4.sto
perl /home/user/perl5/lib/perl5/Bio/App/SELEX/stock2fasta.pl test_rnd4.sto > test_rnd4.fasta


#round4
/share/apps/bin/cmalign -o test_rnd4_cmaligned.sto test.cm test_rnd4.fasta
/share/apps/bin/cmbuild test_rnd4_aln.cm test_rnd4_cmaligned.sto
/share/apps/bin/cmcalibrate test_rnd4_aln.cm
/share/apps/bin/cmsearch --toponly -E 0.1 --tabfile test_rnd4.tab test_rnd4_aln.cm search.fasta

awk '$1!~/^#/{print $2}' test_rnd4.tab > test_rnd4_clusters_found.txt

grep -w -f test_rnd4_clusters_found.txt search.sto > test_rnd5.sto
perl /home/user/perl5/lib/perl5/Bio/App/SELEX/stock2fasta.pl test_rnd5.sto > test_rnd5.fasta


#round5
/share/apps/bin/cmalign -o test_rnd5_cmaligned.sto test.cm test_rnd5.fasta
/share/apps/bin/cmbuild test_rnd5_aln.cm test_rnd5_cmaligned.sto
/share/apps/bin/cmcalibrate test_rnd5_aln.cm
/share/apps/bin/cmsearch --toponly -E 0.1 --tabfile test_rnd5.tab test_rnd5_aln.cm search.fasta

awk '$1!~/^#/{print $2}' test_rnd5.tab > test_rnd5_clusters_found.txt

grep -w -f test_rnd5_clusters_found.txt search.sto > test_rnd6.sto
perl /home/user/perl5/lib/perl5/Bio/App/SELEX/stock2fasta.pl test_rnd6.sto > test_rnd6.fasta


#round6
/share/apps/bin/cmalign -o test_rnd6_cmaligned.sto test.cm test_rnd6.fasta
/share/apps/bin/cmbuild test_rnd6_aln.cm test_rnd6_cmaligned.sto
/share/apps/bin/cmcalibrate test_rnd6_aln.cm
/share/apps/bin/cmsearch --toponly -E 0.1 --tabfile test_rnd6.tab test_rnd6_aln.cm search.fasta

awk '$1!~/^#/{print $2}' test_rnd6.tab > test_rnd6_clusters_found.txt

grep -w -f test_rnd6_clusters_found.txt search.sto > test_rnd7.sto
perl /home/user/perl5/lib/perl5/Bio/App/SELEX/stock2fasta.pl test_rnd7.sto > test_rnd7.fasta


#round7
/share/apps/bin/cmalign -o test_rnd7_cmaligned.sto test.cm test_rnd7.fasta
/share/apps/bin/cmbuild test_rnd7_aln.cm test_rnd7_cmaligned.sto
/share/apps/bin/cmcalibrate test_rnd7_aln.cm
/share/apps/bin/cmsearch --toponly -E 0.1 --tabfile test_rnd7.tab test_rnd7_aln.cm search.fasta

awk '$1!~/^#/{print $2}' test_rnd7.tab > test_rnd7_clusters_found.txt

grep -w -f test_rnd7_clusters_found.txt search.sto > test_rnd8.sto
perl /home/user/perl5/lib/perl5/Bio/App/SELEX/stock2fasta.pl test_rnd8.sto > test_rnd8.fasta


#round8
/share/apps/bin/cmalign -o test_rnd8_cmaligned.sto test.cm test_rnd8.fasta
/share/apps/bin/cmbuild test_rnd8_aln.cm test_rnd8_cmaligned.sto
/share/apps/bin/cmcalibrate test_rnd8_aln.cm
/share/apps/bin/cmsearch --toponly -E 0.1 --tabfile test_rnd8.tab test_rnd8_aln.cm search.fasta

awk '$1!~/^#/{print $2}' test_rnd8.tab > test_rnd8_clusters_found.txt

grep -w -f test_rnd8_clusters_found.txt search.sto > test_rnd9.sto
perl /home/user/perl5/lib/perl5/Bio/App/SELEX/stock2fasta.pl test_rnd9.sto > test_rnd9.fasta


#round9
/share/apps/bin/cmalign -o test_rnd9_cmaligned.sto test.cm test_rnd9.fasta
/share/apps/bin/cmbuild test_rnd9_aln.cm test_rnd9_cmaligned.sto
/share/apps/bin/cmcalibrate test_rnd9_aln.cm
/share/apps/bin/cmsearch --toponly -E 0.1 --tabfile test_rnd9.tab test_rnd9_aln.cm search.fasta

awk '$1!~/^#/{print $2}' test_rnd9.tab > test_rnd9_clusters_found.txt

grep -w -f test_rnd9_clusters_found.txt search.sto > test_rnd10.sto
perl /home/user/perl5/lib/perl5/Bio/App/SELEX/stock2fasta.pl test_rnd10.sto > test_rnd10.fasta


#round10
/share/apps/bin/cmalign -o test_rnd10_cmaligned.sto test.cm test_rnd10.fasta
/share/apps/bin/cmbuild test_rnd10_aln.cm test_rnd10_cmaligned.sto
/share/apps/bin/cmcalibrate test_rnd10_aln.cm
/share/apps/bin/cmsearch --toponly -E 0.1 --tabfile test_rnd10.tab test_rnd10_aln.cm search.fasta

awk '$1!~/^#/{print $2}' test_rnd10.tab > test_rnd10_clusters_found.txt

grep -w -f test_rnd10_clusters_found.txt search.sto > test_rnd11.sto
perl /home/user/perl5/lib/perl5/Bio/App/SELEX/stock2fasta.pl test_rnd11.sto > test_rnd11.fasta


__[ config ]__
[Flags_for]
RNAalifold=-r -cv 0.6 -nc 10 -p -d2 -noLP -color -aln
mafft=--preservecase --clustalout

[executables]
CreateStockholm=perl /home/user/perl5/lib/perl5/Bio/App/SELEX/CreateStockholm.pm
RNAalifold=/share/apps/bin/RNAalifold
cmalign=/share/apps/bin/cmalign
cmbuild=/share/apps/bin/cmbuild
cmcalibrate=/share/apps/bin/cmcalibrate
cmsearch=/share/apps/bin/cmsearch
mafft=/share/apps/bin/mafft
stock2fasta=perl /home/user/perl5/lib/perl5/Bio/App/SELEX/stock2fasta.pl
