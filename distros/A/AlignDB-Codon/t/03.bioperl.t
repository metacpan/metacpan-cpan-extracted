use strict;
use warnings;

use Test::More;

use AlignDB::Codon;

SKIP: {
    eval { require Bio::Align::DNAStatistics };

    skip "Bio::Align::DNAStatistics not installed", 2 if $@;

    # syn_sites
    my $codon_obj = AlignDB::Codon->new( table_id => 1 );
    my $comp_obj = Bio::Align::DNAStatistics->new;

    is_deeply( $codon_obj->syn_sites, $comp_obj->get_syn_sites, "syn_sites" );

    # syn_changes
    is_deeply( $codon_obj->syn_changes, { $comp_obj->get_syn_changes }, "syn_changes" );
}

done_testing(2);
