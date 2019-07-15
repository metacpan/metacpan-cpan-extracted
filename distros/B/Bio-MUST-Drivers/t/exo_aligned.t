#!/usr/bin/env perl

use Test::Most;

use autodie;
use feature qw(say);

use Module::Runtime qw(use_module);
use Path::Class qw(file);

use Bio::MUST::Core;
use Bio::MUST::Drivers;

my $class = 'Bio::MUST::Drivers::Exonerate::Aligned';


# Note: provisioning system is not enabled to help tests to pass on CPANTS
my $app = use_module('Bio::MUST::Provision::Exonerate')->new;
unless ( $app->condition ) {
    plan skip_all => <<"EOT";
skipped all Exonerate tests!
If you want to use this module you need to install the Exonerate executable:
https://www.ebi.ac.uk/about/vertebrate-genomics/software/exonerate
If you --force installation, I will eventually try to install Exonerate with brew:
https://brew.sh/
EOT
}

my @exp_attrs = (
    [ '1', '247', '1430', '2183', '1215' ],
    [ '1', '247', '1430', '2184', '1215' ],
    [ '1', '247', '1430', '2185', '1225' ],
    [ '1', '247', '1430', '2181', '1197' ],
    [ '1', '247', '1430', '2176', '1212' ],
);

# read expected target seqs
my $exp_seqs = Bio::MUST::Core::Ali->load( file('test', 'exo_aligned.ali') );
my $seq_i = 0;

{
    my $pep = Bio::MUST::Core::Ali->load( file('test', 'pep.fasta') );

    for my $i (1..5) {
        my $infile = file('test', "dna$i.fasta");
        my $dna = Bio::MUST::Core::Ali->load($infile);

        my $exo = $class->new(
            dna_seq => $dna->get_seq(0),
            pep_seq => $pep->get_seq(0),
            code    => 1,
        );

        my   $query_seq = $exo->query_seq->seq;
        my  $target_seq = $exo->target_seq->seq;
        my $spliced_seq = $exo->spliced_seq->seq;
#         explain $query_seq;
#         explain $target_seq;
        cmp_ok     length( $query_seq), '==', length( $target_seq),
            "got same length for query and target for dna$i/pep$i";
        cmp_ok 3 * length($target_seq), '==', length($spliced_seq),
            "got expected length for target DNA and protein for dna$i/pep$i";
        is_deeply [ map {
            $exo->$_
        } qw(query_start query_end target_start target_end score) ],
            $exp_attrs[ $i - 1 ],
            "got expected attributes for dna$i/pep$i";

        cmp_ok $target_seq, 'eq', $exp_seqs->get_seq( $seq_i++ )->seq,
            "got expected target_seq for dna$i/pep$i";
    }
}

{
    FILE:
    for my $e ( qw(B M N R S T I J C W X Y Z F A L Q D E U K O) ) {
        my $pep = Bio::MUST::Core::Ali->load( file('test', "pep$e.fasta") );
        my $dna = Bio::MUST::Core::Ali->load( file('test', "dna$e.fasta") );

        my $exo = $class->new(
            dna_seq => $dna->get_seq(0),
            pep_seq => $pep->get_seq(0),
            code    => 1,
        );

        my   $query_seq = $exo->query_seq->seq;
        my  $target_seq = $exo->target_seq->seq;
        my $spliced_seq = $exo->spliced_seq->seq;
#         explain $query_seq;
#         explain $target_seq;
        cmp_ok     length( $query_seq), '==', length($target_seq),
            "got same length for query and target for dna$e/pep$e";
        cmp_ok 3 * length($target_seq), '==', length($spliced_seq),
            "got expected length for target DNA and protein for dna$e/pep$e";

        next FILE if $e =~ m/[ZK]/xms;
                # empty seqs are not kept by Ali->load()

        cmp_ok $target_seq, 'eq', $exp_seqs->get_seq( $seq_i++ )->seq,
            "got expected target_seq for file dna$e/pep$e";
    }
}

# TODO: re-enable once exonerate handles non-standard genetic codes

# {
#     my $pep = Bio::MUST::Core::Ali->load( file('test', "ciliates.pep") );
#     my $dna = Bio::MUST::Core::Ali->load( file('test', "ciliates.dna") );
#
#     my $exo = $class->new(
#         dna_seq => $dna->get_seq(0),
#         pep_seq => $pep->get_seq(0),
#         code    => q{FFLLSSSSYYQQCC*WLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG},
#     );
#
#     my  $query_seq = $exo->query_seq->seq;
#     my $target_seq = $exo->target_seq->seq;
#     explain $query_seq;
#     explain $target_seq;
# }

done_testing;
