#!/usr/bin/env perl
use rlib '.';
use strict; use warnings;
use Test::More;
use Helper;
note( "Testing bioseq single-letter options on test-bioseq.nuc" );

my %notes = (
    d => 'delete by order',
    g => 'remove gaps',
    l => 'protein sequence length',
    n => 'number of sequences',
    r => 'reverse compliment sequence',
    A => 'anonymize sequence IDs',
    B => 'break into single-sequence files',
    L => 'linearize fast sequence',
    X => 'remove stop codons',
);

for my $letter (qw(c g l n r A B C G L X)) {
    run_bio_program('bioseq', 'test-bioseq.nuc', "-${letter}",
		    "opt-${letter}.right", {note=>$notes{$letter}});
}

note( "Testing bioseq option-value options on test-bioseq.nuc" );
%notes = (
    d => 'delete by order',
    p => 'pick 1 sequence by order',
    s => 'get subsequences',
    t => 'translate dna',
    R => 'reloop a sequence',
);

for my $tup (['d', 'order:2'],
	     ['p', 'order:2'],
	     ['s', '10,20'],
	     ['t', '1'],
	     ['R', '3'],
    )
{
    run_bio_program('bioseq', 'test-bioseq.nuc', "-$tup->[0] $tup->[1]",
		    "opt-$tup->[0].right", {note=>$notes{$tup->[0]}});
}

# note( "Testing other bioaln option-value options" );
# my $nuc = test_file_name('test-bioaln-pep2dna.nuc');
# my $aln = test_file_name('test-bioaln-pep2dna.aln');
# for my $triple (['i', 'fasta', 'test-bioaln-pep2dna.nuc'],
# 		['s', '80,100', 'test-bioaln.aln'],
# 		['P', $nuc, 'test-bioaln-pep2dna.aln'])
# {
#     run_bio_program('bioaln', $triple->[2], "-$triple->[0] $triple->[1]",
# 		    "opt-$triple->[0].right");
# }



done_testing();
