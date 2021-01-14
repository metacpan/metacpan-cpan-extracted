#!/usr/bin/env perl

use Test::Most;

use autodie;
use feature qw(say);

use List::AllUtils;
use Path::Class qw(file);

use Bio::MUST::Core;
use Bio::MUST::Core::Utils qw(cmp_store);

my $class = 'Bio::MUST::Core::SeqMask';

my @exp_masks = (
    [ [ qw( 0 1 0 1 0 1 0 1 0 1 ) ],
        [ [2,2], [4,4], [6,6], [8,8], [10,10] ],
        [ qw( 0 1 0 1 0 1 0 1 0 1 ) ],
        [ qw( 1 0 1 0 1 0 1 0 1 0 1 ) ],
        [ qw(ATGTGC ATGCGT) ] ],
    [ [ qw( 1 0 1 0 1 0 1 0 1 0 ) ],
        [ [1,1], [3,3], [5,5], [7,7], [9,9] ],
        [ qw( 1 0 1 0 1 0 1 0 1 ) ],
        [ qw( 0 1 0 1 0 1 0 1 0 1 1 ) ],
        [ qw(G*ACAC GTA*AT) ] ],
    [ [ qw( 0 1 0 1 0 1 0 1 0 1 0 ) ],
        [ [2,2], [4,4], [6,6], [8,8], [10,10] ],
        [ qw( 0 1 0 1 0 1 0 1 0 1 ) ],
        [ qw( 1 0 1 0 1 0 1 0 1 0 1 ) ],
        [ qw(ATGTGC ATGCGT) ] ],
    [ [ qw( 1 0 1 0 1 0 1 0 1 0 1 ) ],
        [ [1,1], [3,3], [5,5], [7,7], [9,9], [11,11] ],
        [ qw( 1 0 1 0 1 0 1 0 1 0 1 ) ],
        [ qw( 0 1 0 1 0 1 0 1 0 1 0 ) ],
        [ qw(G*ACA GTA*A) ] ],
    [ [ qw( 1 1 0 0 1 1 0 0 1 1 ) ],
        [ [1,2], [5,6], [9,10] ],
        [ qw( 1 1 0 0 1 1 0 0 1 1 ) ],
        [ qw( 0 0 1 1 0 0 1 1 0 0 1 ) ],
        [ qw(T*TCC TTC*T) ] ],
    [ [ qw( 0 0 1 1 0 0 1 1 0 0 ) ],
        [ [3,4], [7,8] ],
        [ qw( 0 0 1 1 0 0 1 1 ) ],
        [ qw( 1 1 0 0 1 1 0 0 1 1 1 ) ],
        [ qw(AGGAGAC AGGAGAT) ] ],
    [ [ qw( 1 1 1 1 1 0 0 0 0 0 ) ],
        [ [1,5] ],
        [ qw( 1 1 1 1 1 ) ],
        [ qw( 0 0 0 0 0 1 1 1 1 1 1 ) ],
        [ qw(ATCGAC AC*GAT) ] ],
    [ [ qw( 0 0 0 0 0 1 1 1 1 1 ) ],
        [ [6,10] ],
        [ qw( 0 0 0 0 0 1 1 1 1 1 ) ],
        [ qw( 1 1 1 1 1 0 0 0 0 0 1 ) ],
        [ qw(AGT*GC AGTTGT) ] ],
    [ [ qw( 0 1 1 1 1 1 0 0 0 0 ) ],
        [ [2,6] ],
        [ qw( 0 1 1 1 1 1 ) ],
        [ qw( 1 0 0 0 0 0 1 1 1 1 1 ) ],
        [ qw(ATCGAC AC*GAT) ] ],
    [ [ qw( 0 0 0 0 1 1 1 1 1 0 ) ],
        [ [5,9] ],
        [ qw( 0 0 0 0 1 1 1 1 1 ) ],
        [ qw( 1 1 1 1 0 0 0 0 0 1 1 ) ],
        [ qw(AGT*AC AGTTAT) ] ],
    [ [ qw( 1 1 1 1 1 1 1 1 1 1 ) ],
        [ [1,10] ],
        [ qw( 1 1 1 1 1 1 1 1 1 1 ) ],
        [ qw( 0 0 0 0 0 0 0 0 0 0 1 ) ],
        [ qw(C T) ] ],
    [ [ qw( 0 0 0 0 0 0 0 0 0 0 ) ],
        [],
        [],
        [ qw( 1 1 1 1 1 1 1 1 1 1 1 ) ],
        [ qw(AGT*GATCGAC AGTTGAC*GAT) ] ],
);

{
    for my $exp_row (@exp_masks) {
        my $seq_mask = $class->new( mask => $exp_row->[0] );
        my $blocks = $seq_mask->mask2blocks;
        is_deeply $blocks, $exp_row->[1],
            'got expected blocks from mask';
        is_deeply $class->blocks2mask($blocks)->mask, $exp_row->[2],
            'got expected mask from blocks';

        my $infile = file('test', 'mask.ali');
        my $ali = Bio::MUST::Core::Ali->load($infile);
        my $negative = $seq_mask->negative_mask($ali);
        is_deeply $negative->mask, $exp_row->[3],
            'got expected negative mask';

        my $filtered = $negative->filtered_ali($ali);
        is_deeply [ map { $_->seq } $filtered->all_seqs ], $exp_row->[4],
            'got expected masked seqs';
    }
}

{
    my $len = 250;
    my @blocks = ( [5,125], [130,200], [195,230] );
    my $first = 4;
    my $last = 229;
    my $count = 222;
    my $states = [ (0) x 4, (1) x 121, (0) x 4, (1) x 101, (0) x 20 ];

    my $mask = $class->empty_mask($len);
    $mask->mark_block( @{$_} ) for @blocks;
    is_deeply $mask->mask, $states,
        'got expected mask from overlapping blocks';

    cmp_ok $mask->first_site, '==', $first, 'got expected first site';
    cmp_ok $mask->last_site, '==', $last, 'got expected last site';
    cmp_ok $mask->count_sites, '==', $count, 'got expected site count';
    cmp_ok $mask->coverage, '==', $count / $len, 'got expected coverage';
}

{
    my $len = 100;
    my @sites = (17, 2, 75);
    my $first = 2;
    my $last = 75;
    my $states = [ (0) x 2, (1), (0) x 14, (1), (0) x 57, (1), (0) x 24 ];

    my $mask = $class->custom_mask($len, \@sites);
    is_deeply $mask->mask, $states,
        'got expected mask from custom list of sites';

    cmp_ok $mask->first_site, '==', $first, 'got expected first site';
    cmp_ok $mask->last_site, '==', $last, 'got expected last site';
    cmp_ok $mask->count_sites, '==', @sites, 'got expected site count';
    cmp_ok $mask->coverage, '==', @sites / $len, 'got expected coverage';
}

# Note: ideal_mask is tested through idealize in ali.t

{
    my $infile = file('test', 'gblocks.fasta');
    my $ali = Bio::MUST::Core::Ali->load($infile);

    my $neutral = $class->neutral_mask($ali);
    cmp_ok $neutral->mask_len, '==', $ali->width,
        'got expected length for neutral mask';
    ok( (List::AllUtils::all { $_ } $neutral->all_states),
        'rightly got only active states for neutral mask');

    my $variable = $class->variable_mask($ali);
    my $constant = $variable->negative_mask($ali);
    my $filtered = $constant->filtered_ali($ali);
    cmp_store(
        obj => $filtered, method => 'store',
        file => 'gblocks_const.ali',
        test => 'wrote expected filtered Ali based on constant mask',
    );

    my $list = Bio::MUST::Core::IdList->new(
        ids => [
            'Medicago truncatula_3880@357479567',
            'Hordeum vulgare_4513@295881652'
        ]
    );
    my $masked = $constant->filtered_ali($ali, $list);
    cmp_store(
        obj => $masked, method => 'store',
        file => 'gblocks_masked.ali',
        test => 'wrote expected masked Ali based on constant mask',
    );
}

# TODO: provision gblocks

SKIP: {
    skip q{Cannot find 'Gblocks' in $PATH}, 3
        unless qx{which Gblocks} && $^O ne 'solaris';
        # Note: Solaris has some Gblocks executable that is not what we need

    my $infile = file('test', 'gblocks.fasta');
    my $ali = Bio::MUST::Core::Ali->load($infile);

    for my $mode ( qw(strict medium loose) ) {
        my $mask = $class->gblocks_mask($ali, $mode);
        my $masked = $mask->filtered_ali($ali);
        cmp_store(
            obj => $masked, method => 'store_fasta',
            file => "gb_$mode.fasta",
            test => 'wrote expected filtered Ali based on Gblocks mask',
        );
    }

    # TODO: test exceptions with shared gaps (gblocks_gaps.fasta)
}

# TODO: provision BMGE

SKIP: {
    skip q{Cannot find 'bmge.sh' in $PATH}, 3 unless qx{which bmge.sh};

    my $infile = file('test', 'bmge.fasta');
    my $ali = Bio::MUST::Core::Ali->load($infile);

    for my $mode ( qw(strict medium loose) ) {
        my $mask = $class->bmge_mask($ali, $mode);
        my $masked = $mask->filtered_ali($ali);
        cmp_store(
            obj => $masked, method => 'store_fasta',
            file => "bmge_$mode.fasta",
            test => 'wrote expected filtered Ali based on BMGE mask',
        );
    }
}

{
    my $infile = file('test', 'supermatrix.ali');
    my $ali = Bio::MUST::Core::Ali->load($infile);

    my $mapper = $ali->std_mapper;
    $ali->shorten_ids($mapper);

    my $mask = $class->variable_mask($ali);
    my $filtered = $mask->filtered_ali($ali);
    cmp_store(
        obj => $filtered, method => 'store_phylip',
        file => 'supermatrix-noconstant.phy',
        args => { clean => 1, chunk => -1 },
        test => 'wrote expected filtered phylip file without constant sites',
    );

    cmp_store(
        obj => $mask, method => 'store',
        file => 'supermatrix-noconstant.msk',
        test => 'wrote expected mask file without constant sites',
    );
    my $inmask = file('test', 'supermatrix-noconstant.msk');
    my $loaded = $class->load($inmask);
    is_deeply $loaded, $mask, 'reloaded expected mask without constant sites';
}

{
    my $infile = file('test', 'supermatrix.ali');
    my $ali = Bio::MUST::Core::Ali->load($infile);

    my $mask = $class->parsimony_mask($ali);
    cmp_store(
        obj => $mask, method => 'store',
        file => 'parsimony.msk',
        test => 'wrote expected mask with parsimony',
    );
}

{
    my $infile = file('test', 'blocks.ali');
    my $ali = Bio::MUST::Core::Ali->load($infile);

    my $blfile = file('test', 'blocks.blocks');
    my $mask = $class->load_blocks($blfile);
    cmp_ok $mask->get_comment(0), 'eq', 'simple test blocks file',
        'read expected comment from blocks file';

    my $masked = $mask->filtered_ali($ali);
    cmp_store(
        obj => $masked, method => 'store',
        file => "blocks-masked.ali",
        test => 'wrote expected filtered Ali based on blocks mask',
    );
}

# and_mask
{
    my $mask1 = [ ( 1, 0, 0, 1, 0, 0, 1, 1, 0, 1, 1, 0, 1) ];
    my $mask2 = [ ( 0, 0, 1, 1, 0, 0, 0, 1, 0, 1 ) ];

    my @exp_states = ( 0, 0, 0, 1, 0, 0, 0, 1, 0, 1, 0, 0, 0 );
    my $exp_mask = $class->new( mask => \@exp_states );
    my $got_mask = $class->and_mask($mask1, $mask2);

    is_deeply $got_mask, $exp_mask,
        'correctly created the new mask with';
}

# or_mask
{
    my $mask1 = [ ( 1, 0, 0, 1, 0, 0, 1, 1, 0, 1, 1, 0, 1) ];
    my $mask2 = [ ( 0, 0, 1, 1, 0, 0, 0, 1, 0, 1 ) ];

    my @exp_states = ( 1, 0, 1, 1, 0, 0, 1, 1, 0, 1, 1, 0, 1 );
    my $exp_mask = $class->new( mask => \@exp_states );
    my $got_mask = $class->or_mask($mask1, $mask2);

    is_deeply $got_mask, $exp_mask,
        'correctly create the new mask with or';
}

# store_blocks
{
    my @mask = qw( 1 1 1 1 0 0 1 0 0 1 1 1 0 0 0 0 1 1 0 1 0 1 1 );
    my $mask = $class->new( mask => \@mask );

    cmp_store(
        obj  => $mask, method => 'store_blocks',
        file => "store_blocks.blocks",
        test => 'wrote expected block file based on mask',
    );
}

# store_una
{
    my $blocks_file = file('test', 'store-una-blocks-align.blocks');
    my $mask = $class->load_blocks($blocks_file);

    my $infile = file('test', 'store-una-ex-seq.ali');
    my $ali = Bio::MUST::Core::Ali->load($infile);
    my $id = 'GIV-Norovirus Cat.GIV.2.POL_1160949@380036198';

    cmp_store(
        obj  => $mask, method => 'store_una',
        file => "store-una.una",
        test => 'wrote expected una file based on mask',
        args => { ali => $ali, id => $id },
    );
}

done_testing;
