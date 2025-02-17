#!/usr/bin/env perl

use Test::Most;

use autodie;
use feature qw(say);

use List::AllUtils;
use Module::Runtime qw(use_module);
use Path::Class qw(file);

use Bio::MUST::Core;
use Bio::MUST::Drivers;


say 'Note: tests designed for: cap3 VersionDate: 12/21/07  Size of long: 8';

my $class = 'Bio::MUST::Drivers::Cap3';

# Note: provisioning system is not enabled to help tests to pass on CPANTS
my $app = use_module('Bio::MUST::Provision::Cap3')->new;
unless ( $app->condition ) {
    plan skip_all => <<"EOT";
skipped all CAP3 tests!
If you want to use this module you need to install the CAP3 executable:
http://seq.cs.iastate.edu/cap3.html
If you --force installation, I will eventually try to install CAP3 with brew:
https://brew.sh/
EOT
}

my @exp_contig_names = (
    'Contig1',
    'Contig2',
    'Contig3',
    'Contig4',
    'Contig5',
);

my @exp_singlet_ids = (
    'gi|125991188',
    'gi|125991187',
    'gi|125991186',
    'gi|125991185',
    'gi|125991183',
    'gi|125991182',
    'gi|125991181',
);

my @exp_contig_seqs = map {
    Bio::MUST::Core::Seq->new( seq_id => 'seq', seq => $_ )
} (
'CTGGACGAGCTGCAGGAGGAGGCGCTGGCGCTGGTGGCGCAGGCCCGACGAGAGGGCGAC
ACGCCGGAAAAGACGCCCCGCGGGGAGAAGCACAACATGTTCCAGGACGCGGGCAAGCCC
TTCAAGGCCCTGGGGAAGAACCTGGGCAAGCTGAAGCCGAAGGACAAGACCAAGGAGGAT
ATCACTGAGATGAAGCGGCTGGTCCAAGAGACCCTTCAGAAGAACATGGACCTCGAGGCC
GAGAACAAGTGGCTCCGGGAGCACTCCAAGAACCGCACTGCGTAAGCCCCAAGCCCCTGC
CCTCACAGCCATCCAACCCGCCCAACCAACCTATGCCCTTATATCTACCCCGCTTCCCCA
TCCCTCCCATATGGCATTTCTTCCCTTGGGTCACAGCACTTTCGTTCCCTGCTGTAACAT
TGCTGACTTTGCCCCCACATTACGCTGTTAAAAAAAAA',
'CTCGCTGCCGAGCTGAAGCAACGGGAGGTGGACCACCAGAACCAGATTGACGCCCTCCAG
AGCCAAATCAGGTGGTATGTGGAGAACCAGGATATGGTGACGAAGAACGACGAGCTGCTC
GCAGCCCAGGCCCAGACCATCGACAACCTGCGGCAGCGGGTGCTGGAGCTGGAGGGCCCC
GCCAAGGAGGCCGGCCGCGGCGAGGCGGGGCTGAAGGCGCGGTACTACCAGAAGCGGATC
GCGGAGCTGGAGGAGGCGCTGCGGCGGGCGGAGAAGGGCCAGCGGGACGACGACATCCCG
GCGCTGATCCGCGCGGTGAAGCCCACGATGGAGGAAACCCAACAGCAGAAACTGTTGCAG
AAGAAGGTGCAGCAGCTGCAGCAGGAGCTGGACGATCAGACGGCCAAGAGCGAGAAGGCC
CTGCGGGTGCTGCGGCTGGAAAGCGACCGCCTGAAGACGAGCTATGAGACGCGGATCGCC
CAGATGGAGGATGACATGAAGATGCGCCTCCGAGGTGCTACGTCAAAGAAAGTTCAGGAA
TTGACACGCCAGCTGGACGAAGCAAGGACATACTACTCGAAGAAGGTTCGAGAGCTTGAA
GCGCAGGTGGTCCAACTGCGCCGGGACCTGAAGGGGCCGGGGCGGGGGGCCGCCCCCGCC
GCGGGCCGAGCGAAGCCGGCTGCTGCTCCCCCGACCGCGGAGGCGGACCTGCTGGCCCCC
GCCGCACCAGCCGCCTCACCCCACCTGGCAGACGGCGGGACCCACCGCTCCCAAGGCACT
CAAGCGGACGTCGTG',
'TGCAGGAATCGCGGCCGCTTTTTTTTTTTTGCGGGCCGCGGCTCCAAGGACAGCGCCCCC
GACAGCCGGTGCCCCAGAGCGATACATAACGCCGGGCCCAGGGGACAGCGGGCCCATATT
GTTTGCCACTGAGGCTTGGGCGGGTGTATGCGTGGGCCGGGGAGACGGTACACGGCATTG
CGATGGGGAGTCGAGGTAGGGTGAGGGCGAGGCAGGCAGGGGGGGAGCCCCAACGGCGCC
ACTGCGGCCGGCGGGGGGTTGTTGGTGCGCGGCGGGAGGGCGGGGCCGCTACGCTGACTT
GATTTGCTCCTCGAACAGGCCCTTCACCCGCACCATCCCCTTCTCCTGCCAGTCAAACTC
CGTGCGGAGGCCCTCCAGCTCCGCATCGTCGCCCTGCACAATCACCTCAGTCTCCTTCAA
CTCGTCATCTGTTATAATCTTCACCTGCAACTCCTGATCCACGTCGGCATTGTCAAGGTA
GTAAGCGGCCGC',
'CCAGCCCGCCATCCACAAATGGCCCAGGTGCCCATCAGCCAACTCCCGTTGGAGGAGCTC
AACCAGGTCAAGGAGCAGCTCGAGACCGAGATCCGCAACCTCGCCCAGTCGCTGCAGGCG
CTGCGGCAGGTGCGGGAGCGGTTCTTTGAGAGCAAGACGTGCATCGAGCACCTGCGGGAG
TACAAGCCGGGGGATAAGGTGCTGGTGCCCCTCACCTCCTCGCTGTACGTGCCGGGGGAG
TTCGGGGACACGTCCCAGTGCATCGTGGACGTCGGGACGGGGTATTACTTGAAGCAGAGC
CTGGAAAAGGGAGAGGACTTCATGGACCGGAAGATGAAGTACATGAAGGAGAACATCGAC
AAGGTGCAGGCCGCCGTCAGCCAGAAGAACCAGCAGCTGAACGCGGTGGTGGAGGAGATG
CAGCGCAAGGTGCAGCAGCAGCGGCAGCAGCGGCCAGCGGAAGGGGCGGCGGCGAAATGA
GTTCCCCCCTGTGTCCTTCCCCTCTGTCCTGCTATTTACACTTGAACTCTGCTGGCGGTG
ACCATCGGGCCTCGTCCCTCATTCACACTTGCGGCACTGACGTTGTGCACTCATGTGACG
ATCCGGCAGCGGCACCCCCACAGCGCTTTCCGCCACAAAAAAAAAAAAAAAAAA',
'TTTTTTTTTTTTTTTTTTTTGCCTCCACTTTTGGGAAATTTTAGTCCAAAAATTGGCGCC
CGTGCAAAAACACAGGAAGGGGACAGGACATGATGCGGTTGGCAGGGGCACGGGGCACCG
TGCAGCGGCCGCGTGTTCCTGGCCGCCCTGATGTGGTACAGTTACGTGGCTCATTTCATC
TTTGTGTTTGCCATCCTGGGCACCGTGTCCTACAACGCGGCGTCGTGGTACTTCGGCGTC
TTCCTCGTCACATACCAGCATCAACTGGAGGAGAAGGCGAAGGAGATCGAGACGCGGCGG
TCGCGGTCCCCCCTTGCCTCCCCCACCAAGGACAGCTGACCGGCCCCCGGGGGTCCGGGC
CATGCCTATTTCTCGCCCCACTCCCAGGCCCCTCCCGAGACCGAGCCTCGCGCGCTGCGG
TCGGAGGCAGTGTTGGTCCGATCCTCTCCCCTGTGTGTTGGGCCTCCTTCGTCGCATTTT
GCTGTGGTGTGGACGTGTGGTGACAAGGGTGTGAGATGTCGCGTGGGCTCTGACCCTCTG
TCGCATGCCACAGCCCCTCGCCTCATCCCGCGCTGACCTGACAGCCGGATGTGCCAGGCC
AGCGTTGGGCAGCCCTTCCACGGAGGGTTGCGCTGCACCGCTGATTCCTCGACGGCTGCA
GAGTTGTATCAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAG',
);

my @exp_singlet_seqs = map {
    Bio::MUST::Core::Seq->new( seq_id => 'seq', seq => $_ )
} (
'GTGAGTGAAATGTCTTAGCACCAGAGGTGCAAATACAAATTGTTCAGCAACGTTGCGGCA
GATCCGTTTACATCGCACAGAGGAAATGTGTCCATGAGGAGGAATGCGATCAATACGGAG
CGGCCGC',
'ACCGTGCCTGGAAGCAAGCAGAGAGGCACGAAAGGCATATGATAATGCGCCTCGCTTATA
TCGATGTTGAGGGCAACAGCGCTGGGAAGCCGAACCCACATGCTGAGGGAAGGGGAGTGG
GAACTCCT',
'CTCGGCCTGCAGAGCCCCTCACACCACTGACCCAGTGCCAGCTCGGCGCCCGTCGCCACT
GCCCGGCAGGCGGGGTATTCATCGCATCGACTTCTGAGGAAGCGACCCTCCTGACGTGCC
CCCTGTACTGTTCGCTTTATTCCCCAAATACATCAACTCTAACC',
'TCTCAGCGGACCACTGTGTGGCAGGTGGCAACCGGGGGCAGAGGTGACCAGCAGGTGGGT
GGGGGCAGCGTAAGGGGAAGGGGAGGACCAGCAAGTCGGCTCGATGACCCGGCTCAGGCC
TCCATCGCCGCGGGGCTCGCCGGCTTGCCCTTCTTCGCCTTGGGGGGCTTGCCTGCCTTG
GGCGCCTTGGCGGCCGTTGGAGTCGCTCCGCCGGCGGGGGCCGAAGGCACTTTGTCTTTG
GAAGCCTTCCGGCTCGCCGCCCCCTTCTTCGCCTCCTTCTTCCGGGCAGTGCGAACCTTC
ACCTTCTTCTTCCCGACCGTGACGCGCCGCTTCGTGCGGGTCCGCCCCGGCTTGATGGGC
TTCATGGGCACCTTGCGCAGGCGGTACAGCACAGCCCCCTTCAGCTTCCTCCGCTTCTTC
ACCGCATCGCCAAACTTGGCCATGTCTGCCTCGATGGTGGTGATCCATTGTCGGACCTGC
TGCTGGTGCTTCGGGGGGAGGGCCGTCCCCACGCGGCAGCGCAGCACGCTCTGCAGGAAG
TCCCGCGCGGCG',
'CGCGGCCGCTTTTTTTTTTTTTGAGCAAATCGAGCACACTGTGGATGGGGAAGGCACTAC
GGCGACCAAAGTGTGTGGATCCTTGGCATCCAGAGGGGGGTCAGCCCTGACACCGCGGGC
TGAGGGCAGTGATGTTGCCACCTGAGGAGCCTGCCAGCTCCTCTGCCACCTCTAGCACAG
AAGCACCTCACACAGGCGGCAAACATGGCAAACAGGGGATGGCGGGCAGGGTCAGGTCAC
TCTACGCTGCGGGTGAGACGATAACTGGCACGGAGAGCCGATGCCGAACACAGATGCGGA
GCAGCCGAATGGATCCGGTGCTTCGCAATTGACGCGAGGGCAGCCGTGCGTGCGGCCCTA
CCCAAGGCGTTGCGAGAGCGGCCGC',
'TATTGAACCATCGCCCGGCGTTGTGCTGCGCGTTATTCCGTGTCCCGCCTCCTGACCGTG
ACCTGCTTGACTGGCTTCCGATCCCCTTTACCATTGCGGCACAGAAAAGGATTGCGATTC
AAAAAAAAAAAAAA',
'CCGCTGACCCCCCGGCCCCACTGGGGCCTGCCCTGCTTGGGCGACGTGGAGGGCCTGCCA
CCTAACCACCATCATCTGTATTTCCCCTTCTGCGGGCATCATACCCCATGTCACCCATCC
CGGCCTTTCCTGCTGACAATCAGCTGACCTCCTCGGGAACATGGATGTCCAGTCTCAACT
GAGGCCAGTTAATGAGAGGCCTGCTCCCACACCACTCCCACCCGGATCGCCAAACACAAA
CACAAACACAGAACTCATACGTACACACCACGCACTACGCATTTGCACGTGCACCCCGCA
CCTCCCCTATTATTCGTT',
);

my @exp_contig_seq_ids = (
    [
    'gi|125991078',
    'gi|109775518',
    ],
    [
    'gi|125991053',
    'gi|109784559',
    ],
    [
    'gi|125991021',
    'gi|125991020',
    'gi|125989076',
    ],
    [
    'gi|125991014',
    'gi|109780664',
    ],
    [
    'gi|125991007',
    'gi|109778688',
    'gi|109773906',
    ]
);

my $cap = $class->new( seqs => file('test', 'seqs4cap3.fasta') );

is_deeply [ $cap->all_contig_names ], \@exp_contig_names,
            'got expected names for all contigs';
is_deeply [ map { $_->full_id } $cap->all_singlets ], \@exp_singlet_ids,
            'got expected SeqIds from singlets';

is_deeply [ map { $_->seq } $cap->all_contigs ],
          [ map { $_->seq } @exp_contig_seqs ],
            'got expected Seqs for all contigs';
is_deeply [ map { $_->seq } $cap->all_singlets ],
          [ map { $_->seq } @exp_singlet_seqs ],
            'got expected Seqs for all singlets';

for my $i (1..5) {
    is_deeply [ map { $_->full_id } @{ $cap->seq_ids_for('Contig' . $i) } ],
            $exp_contig_seq_ids[$i-1],
            "got expected SeqIds for fragments of Contig $i";
}

is_deeply [ map { [ map { $_->full_id } @{$_} ] } $cap->all_contig_seq_ids ],
            \@exp_contig_seq_ids,
            'got expected SeqIds for all contig fragments';

done_testing;
