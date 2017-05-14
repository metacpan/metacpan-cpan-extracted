#!/usr/bin/env perl
use rlib '.';
use strict; use warnings;
use Test::More;
use Config;
use Helper;


# option background (background needs special care)
my %notes = (
    'avpid' => 'average percent identity',
    'codon-view' => 'codon view',
    'conblocks' => 'extract conserved blocks',
    'concat' => 'concatenate aln files',
    'dna2pep' => 'CDS alignment to protein alignment',
    'length' => 'length of an alignment',
    'listids' => 'list all sequence IDs',
    'match' => 'match view',
    'noflatname' => 'set display name flat',
    'nogaps' => 'remove gapped sites',
    'numseq' => 'number of aligned sequences',
    'select-third' => 'extract third site',
    'uniq' => 'remove redundant sequences',
    'varsites' => 'show only variable sites',
);

test_no_arg_opts('bioaln', 'test-bioaln.cds', \%notes);

my $opts = [
    ['aln-index', 'B31,1',
     "get align column index of seq 'B31', residue 1"],
    ['consensus', '90',
     'add a 90% consensus sequence'],
    ['delete', 'JD1,118a',
     'delete sequences JD1, 118a'],
    ['erasecol', 'B31',
     'Erase sites gapped at B31'],
    ['output', 'fasta',
     'output a FASTA alignments'],
    ['pick', 'JD1,118a,N40',
     'pick sequences JD1, 118a, N40'],
    ['refseq', 'B31',
     'change reference (or first) sequence'],
    ['window', '60',
     'average identifies for sliding windows of 60']
    ];

test_one_arg_opts('bioaln', 'test-bioaln.cds', $opts);

note( "Testing other bioaln option-value options" );

my $nuc = test_file_name('test-bioaln-pep2dna.nuc');
for my $tuple (['input', 'fasta', 'test-bioaln-pep2dna.nuc',
		 "input is a FASTA alignment"],
		['slice', '80,100', 'test-bioaln.aln',
		 "alignment slice from 80-100"],
		['pep2dna', $nuc, 'test-bioaln-pep2dna.aln',
		 "Back-align CDS sequence according to protein alignment"])
{
    run_bio_program('bioaln', $tuple->[2], "--$tuple->[0] $tuple->[1]",
		    "opt-$tuple->[0].right", {note=>$tuple->[3]});
}


%notes = (
    'bootstrap' => "bootstrap",
    'permute-states' => "permute-states",
    'uppercase' => "Make an uppercase alignment",
    'resample' => "Resample",
);


for my $opt (keys %notes) {
    run_bio_program_nocheck('bioaln', 'test-bioaln.cds', "--${opt}",
			    {note=>$notes{$opt}});
}

done_testing();
