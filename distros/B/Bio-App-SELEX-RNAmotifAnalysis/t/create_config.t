#!/usr/bin/env perl
use 5.008;    # Require at least Perl version 5.8
use strict;   # Must declare all variables before using them
use warnings; # Emit helpful warnings
use autodie;  # Fatal exceptions for common unrecoverable errors (e.g. w/open)

# Testing-related modules
use Test::More;                  # provide testing functions (e.g. is, like)
use Test::LongString;            # Compare strings byte by byte
use Data::Section -setup;        # Set up labeled DATA sections
use File::Temp  qw( tempfile );  #
use File::Slurp qw( slurp    );  # Read a file into a string

SKIP: {
    skip 'Author tests', 2 unless $ENV{RUN_DEVELOPER_TESTS};
    system("perl lib/Bio/App/SELEX/RNAmotifAnalysis.pm --fastq dummy ");
    my $config_file = 'cluster.cfg';
    my $result   = slurp $config_file;
    my $expected = string_from('expected');
    is( $result, $expected, 'successfully created config file' );
    delete_temp_file( $config_file);
}

{
    system("perl lib/Bio/App/SELEX/RNAmotifAnalysis.pm --fastq dummy ");
    my $config_file = 'cluster.cfg';

    ok( -e $config_file, 'created a config file' );
    delete_temp_file( $config_file);
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

sub delete_temp_file {
    my $filename  = shift;
    my $delete_ok = unlink $filename;
    ok($delete_ok, "deleted temp file '$filename'");
}

#------------------------------------------------------------------------
# IMPORTANT!
#
# Each line from each section automatically ends with a newline character
#------------------------------------------------------------------------

__DATA__
__[ expected ]__
[Flags_for]
RNAalifold=-r -cv 0.6 -nc 10 -p -d2 -noLP -color -aln
mafft=--preservecase --clustalout

[executables]
CreateStockholm=selex_clustal2stockholm.pl
RNAalifold=RNAalifold
cmalign=cmalign
cmbuild=cmbuild
cmcalibrate=cmcalibrate
cmsearch=cmsearch
mafft=mafft
stock2fasta=selex_stock2fasta.pl
