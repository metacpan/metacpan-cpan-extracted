#!/usr/bin/env perl

use Test::Most;

use autodie;
use feature qw(say);

use Path::Class qw(file);

use Bio::MUST::Core;
use Bio::MUST::Core::Utils qw(change_suffix cmp_store);

my $class = 'Bio::MUST::Core::Tree';

my @exp_abbr_ids = ( qw(295881652 302595059 357123620 315623028 242096926
    302803464 7269912 296090298 356550732 357479567
) );

my @exp_long_ids = (
    'Hordeum vulgare_4513@295881652',
    'Triticum aestivum_4565@302595059',
    'Brachypodium distachyon_15368@357123620',
    'Oryza sativa_39947@315623028',
    'Sorghum bicolor_4558@242096926',
    'Selaginella moellendorffii_88036@302803464',
    'Arabidopsis thaliana_3702@7269912',
    'Vitis vinifera_29760@296090298',
    'Glycine max_3847@356550732',
    'Medicago truncatula_3880@357479567'
);

{
    my $infile = file('test', 'plantae.arb');
    my $tree = $class->load($infile);
    isa_ok $tree, $class, $infile;
    is $tree->count_comments, 6, 'read expected number of comments';
    is $tree->header, <<'EOT', 'got expected header';
# Sequences extracted from Plantae.ali of the 1 October 2012 at 9 hours 40
# File Plantae_ml.nbs created on 1 October 2012 at 9 hours 40
# 12737 positions remain on the 38214 aligned positions
# life.col,life.nom
# -528290.26
# There are 84 species
EOT
    cmp_store(
        obj => $tree, method => 'store_arb',
        file => 'plantae.arb',
        test => 'wrote expected .arb file',
    );
    cmp_store(
        obj => $tree, method => 'store_arb',
        file => 'plantae_ali.arb',
        test => 'wrote expected .arb file with link to .ali',
        args => { alifile => 'path-to/another.ali' },
    );
}

# TODO: provision phyml

SKIP: {
    skip q{Cannot find 'phyml' in $PATH}, 5 unless qx{which phyml};

    my $alifile = file('test', 'gb_strict.fasta');
    my $ali = Bio::MUST::Core::Ali->load($alifile);
    my $mapper = $ali->acc_mapper;
    $ali->shorten_ids($mapper);

    my $phyfile = file('test', 'my_gb_strict.phy');
    $ali->store_phylip($phyfile);
    qx{phyml -i $phyfile -d aa -c 1 -b -2 > /dev/null 2> /dev/null};

    my $trefile = $phyfile . '_phyml_tree.txt';
    my $tree = $class->load($trefile);
    isa_ok $tree, $class, $trefile;
    is $tree->count_comments, 0, 'read expected number of comments';
    explain [ map { $_->full_id } $tree->all_seq_ids ];
    cmp_bag [ map { $_->full_id } $tree->all_seq_ids ], \@exp_abbr_ids,
        'got expected abbr_ids from tree';

#     use Bio::Phylo::Treedrawer;
#     my $td = Bio::Phylo::Treedrawer->new(
#             -width  => 400,
#             -height => 600,
#             -shape  => 'RECT',
#             -mode   => 'CLADO',
#             -format => 'PDF',
#     );
#     $td->set_padding(50);
#
#   $td->set_tree($tree->tree);
#   open my $out1, '>', file('test', 'test1.pdf');
#   print {$out1} $td->draw;

    $tree->restore_ids($mapper);
    explain [ map { $_->full_id } $tree->all_seq_ids ];
    cmp_bag [ map { $_->full_id } $tree->all_seq_ids ], \@exp_long_ids,
        'got expected long_ids from tree after restoring ids';

    my ($version) = qx{phyml -v} =~ m/PhyML\s(v3\.0)/xms;
    skip qq{PhyML version is not 3.0: $version}, 1
        unless $version && $version eq 'v3.0';

    cmp_store(
        obj => $tree, method => 'store_arb',
        file => 'gb_strict.phy_phyml_tree.arb',
        test => 'wrote expected .arb file after restoring ids',
    );
}

{
    my $infile = file('test', 'PBP3.tre');
    my $tree = $class->load($infile);
    cmp_store(
        obj => $tree, method => 'store_arb',
        file => 'PBP3.arb',
        test => 'wrote expected .arb file from .tre file (discarding BP)',
    );
}

{
    my $infile = file('test', 'FTSW.tre');
    my $tree = $class->load($infile);
    cmp_store(
        obj => $tree, method => 'store_tpl',
        file => 'FTSW.tpl',
        test => 'wrote expected .tpl file from .tre file (disc. BP and BL)',
    );

    cmp_store(
        obj => $tree, method => 'store',
        file => 'FTSW.tre',
        test => 'wrote expected .tre file after store_tpl (no side-effect)',
    );

}

{
    for my $base ( qw(unrooted-bp unrooted-pp rooted-bp rooted-pp) ) {
        my $infile = file('test', "$base.tre");
        my $tree = $class->load($infile);
        cmp_store(
            obj => $tree, method => 'store_grp',
            file => "$base.grp",
            test => 'wrote expected .grp file from .tre file',
        );

# Cannot easily test because of varying date
#         cmp_store(
#             obj => $tree, method => 'store_nbs',
#             file => "$base.nbs",
#             test => 'wrote expected .grp file from .tre file',
#         );
    }
}

{
    my $infile = file('test', 'seqid-grp-nbs.tre');
    my $tree = $class->load($infile);
    cmp_store(
        obj => $tree, method => 'store_grp',
        file => "seqid-grp-nbs.grp",
        test => 'wrote expected .grp file from .tre file (smart SeqIds)',
    );
}

# TODO: test this!
# {
#   my $infile1 = file('test', 'G12210-O-S-1-NO.tre');
#   my $infile2 = file('test', 'G12210-O-S-1-NO-ref.tre');
#   my $tree1 = Bio::MUST::Core::Tree->load($infile1);
#   my $tree2 = Bio::MUST::Core::Tree->load($infile2);
#
#   my $hash_ref = $tree1->match_branch_lengths($tree2);
#   while (my ($clade, $bls_ref) = each %{$hash_ref}) {
#       say join "\t", qq{'$clade'}, @{ $bls_ref };
#   }
#   explain $hash_ref;
#
#   my $fac = Bio::Phylo::Factory->new;
#   my $forest = $fac->create_forest;
#   $forest->insert($tree1->tree);
#   $forest->insert($tree2->tree);
#   my $consensus = $forest->make_consensus;
#   say $consensus->to_newick;
# }

# TODO: test switch_branch_lengths_and_labels_for_entities
# TODO: check standard store (with BSV)

done_testing;
