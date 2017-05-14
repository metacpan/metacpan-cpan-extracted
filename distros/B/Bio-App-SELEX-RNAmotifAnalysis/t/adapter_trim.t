#!/usr/bin/env perl
use 5.008;                  # Require at least Perl version 5.8
use strict;                 # Must declare all variables before using them
use warnings;               # Emit helpful warnings
use autodie;                # Automatically throw fatal exceptions for common unrecoverable
                            #   errors (e.g. trying to open a non-existent file)

use Test::More;                  # Testing module
use Test::LongString;            # Compare strings byte by byte
use File::Temp  qw( tempfile );  #
use Data::Section -setup;        # Have various DATA sections, allows for mock files
use File::Slurp qw( slurp);

test_system(
    outfile => 't/trim_AGGT_out',
);

{    # Test trimming both ends 
    my $outfile = 't/trimmed_AGGT_TTG';
    system( "bin/selex_adapter_trimmer --fastq --infile=t/sample.fastq --outfile=$outfile --adapterseq=AGGT --adapter3prime=TTG");

    my $result   = slurp $outfile;
    my $expected = slurp 't/expected_AGGT_TTG.fastq';

    is_string( $result, $expected, 'AGGT and TTG trimming successful' );

    delete_temp_file($outfile);
}

done_testing();

sub test_system {
    my %opt = @_;
    system ("bin/selex_adapter_trimmer --fastq --infile=t/sample.fastq --outfile=$opt{outfile} --adapterseq=AGGT");

    my $result   = slurp $opt{outfile};
    my $expected = slurp 't/expected_trimAGGT.fastq';

    is_string( $result, $expected, 'Simple trim of AGGT successful' );

    delete_temp_file($opt{outfile});
}

sub delete_temp_file {
    my $filename = shift;
    my $unlinked_ok = unlink $filename;
    ok($unlinked_ok, "Deleted temp file '$filename'");
}

