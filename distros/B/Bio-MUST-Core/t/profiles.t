#!/usr/bin/env perl

use Test::Most;

use autodie;
use feature qw(say);

use List::AllUtils;
use Path::Class qw(file);

use Bio::MUST::Core;
use Bio::MUST::Core::Utils qw(cmp_store);

my $class = 'Bio::MUST::Core::SeqMask::Profiles';

my %exp_count_for = (
    0.00 => 169,
    0.01 => 169,
    0.05 => 139,
    0.10 => 120,
    0.20 => 96,
    0.30 => 85,
    0.40 => 78,
    0.50 => 70,
    0.90 => 3,
    1.00 => 0,
);

{
    my @infiles = map { file('test', "ppred-$_.phy") } 1..50;
    my @alis = map { Bio::MUST::Core::Ali->load_phylip($_) } @infiles;
    my $alifile = file('test', 'for-ppred-prof.phy');
    my $ali = Bio::MUST::Core::Ali->load_phylip($alifile);

    {
        my $sim = Bio::MUST::Core::IdList->new( ids => [ 'Karlodiniu' ] );
        my $profiles = $class->ppred_profiles(\@alis, { sim_list => $sim } );
        my $obs = Bio::MUST::Core::IdList->new( ids => [ 'Vitrella_b' ] );
        my $freqs = $profiles->ppred_freqs($ali, { obs_list => $obs } );

        for my $min ( sort { $a <=> $b } keys %exp_count_for ) {
            my $mask = $freqs->freqs_mask($min, 1.0);
            my $count = $mask->count_sites;
            cmp_ok $count, '==', $exp_count_for{$min},
                "got expected site count for $min: $count";
        }
    }

    {
        my $profiles = $class->ppred_profiles(\@alis);

        cmp_store(
            obj => $profiles, method => 'store',
            file => 'ppred-freqs-by-seq.tsv',
            test => 'wrote expected ppred freqs .tsv file',
        );

        my $freqs = $profiles->ppred_freqs($ali, { by_seq => 1 } );

        cmp_store(
            obj => $freqs, method => 'store',
            file => 'obs-ppred-freqs.tsv',
            test => 'wrote expected observed freqs .tsv file',
        );

        cmp_store(
            obj => $freqs, method => 'store',
            file => 'obs-ppred-freqs-reorder.tsv',
            test => 'wrote expected reordered observed freqs .tsv file',
            args => { reorder => 1 },
        );
    }
}

done_testing;
