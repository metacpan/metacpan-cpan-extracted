#!/usr/bin/env perl

use Test::Most;

use autodie;
use feature qw(say);

use List::AllUtils;
use Path::Class qw(file);

use Bio::MUST::Core;
use Bio::MUST::Core::Utils qw(cmp_store);

my $class = 'Bio::MUST::Core::IdList';

{
    my $list = $class->new( ids => [ map { "seq$_" } 1..3 ] );
    cmp_ok $list->count_indices, '==', 3,
        'got expected number of indices: 3';

    $list->add_id( map { "seq$_" } 4..6 );
    cmp_ok $list->count_indices, '==', 6,
        'got expected number of indices after array expansion: 6';
}

{
    my $list = $class->new();

    $list->add_id('seq1');
    $list->add_id('seq2');
    $list->add_id('seq3');
    cmp_ok $list->count_indices, '==', 3,
        'got expected number of indices after stepwise array expansion: 3';
}

my @exp_ids = (
    'Acholeplasma laidlawii_441768@162448101',
    'Curvibacter putative_667019@260221396',
    'Desulfotomaculum gibsoniae_767817@357041591',
    'Lysinibacillus fusiformis_714961@299534964',
    'Solibacillus silvestris_1002809@327439945',
);

{
    my $infile = file('test', 'AhHMA4_5.idl');
    my $list = $class->load($infile);
    isa_ok $list, $class, $infile;
    is $list->count_comments, 1, 'read expected number of comments';
    is $list->count_ids, 5, 'read expected number of ids';
    is $list->header, <<'EOT', 'got expected header';
# simple test id list
#
EOT
    is_deeply $list->ids, \@exp_ids, 'got expected ids from .idl file';

    cmp_store(
        obj => $list, method => 'store',
        file => 'AhHMA4_5.idl',
        test => 'wrote expected .idl file',
    );
}

{
    my $infile = file('test', 'AhHMA4_5.lis');
    my $list = $class->load_lis($infile);
    isa_ok $list, $class, $infile;
    is $list->count_comments, 2, 'read expected number of comments';
    is $list->count_ids, 5, 'read expected number of ids';
    is $list->header, <<'EOT', 'got expected header';
# simple test id list
# in MUST format
EOT
    is_deeply $list->ids, \@exp_ids, 'got expected ids from .lis file';

    cmp_store(
        obj => $list, method => 'store_lis',
        file => 'AhHMA4_5.lis',
        test => 'wrote expected .lis file',
    );
}

{
    my $infile = file('test', 'AhHMA4.ali');
    my $ali = Bio::MUST::Core::Ali->load($infile);
    my $list = $class->new(ids => \@exp_ids);

    # execute twice the following test with or without lookup
    for my $lookup ($ali->new_lookup, undef) {

        my $reordered_ali = $list->reordered_ali($ali, $lookup);
        cmp_store(
            obj => $reordered_ali, method => 'store',
            file => 'AhHMA4_5_reordered.ali',
            test => 'wrote expected reordered Ali',
        );

        my $filtered_ali = $list->filtered_ali($ali, $lookup);
        cmp_store(
            obj => $filtered_ali, method => 'store',
            file => 'AhHMA4_5_filtered.ali',
            test => 'wrote expected reordered Ali',
        );

        # check independence of deep-copied objects
        my $blah = 'XXX';
        for my $seq ($filtered_ali->all_seqs) {
            $seq->edit_seq(0, $seq->seq_len, $blah);
        }
        ok( (List::AllUtils::any { $_->seq eq $blah }  $filtered_ali->all_seqs),
            'rightly modified filtered seqs');
        ok( (List::AllUtils::all { $_->seq ne $blah } $reordered_ali->all_seqs),
            'rightly left reordered seqs untouched');
    }
}

my @filt_ids_miss = (
    'Desulfotomaculum gibsoniae_767817@357041591',
    'Solibacillus silvestris_1002809@327439945',
    'Acholeplasma laidlawii_441768@162448101',
);

my @reor_ids_miss = (
    'Acholeplasma laidlawii_441768@162448101',
    'Desulfotomaculum gibsoniae_767817@357041591',
    'Solibacillus silvestris_1002809@327439945',
);

{
    my $infile = file('test', 'AhHMA4.ali');
    my $ali = Bio::MUST::Core::Ali->load($infile);
    my $list = $class->new(ids => \@exp_ids);

    # check in situ modification
    $ali->apply_list($list);
    cmp_bag [ map { $_->full_id } $ali->all_seq_ids ], [ $list->all_ids ],
        'rightly applied id list to Ali';

    # check handling of missing ids in lists
    $ali->delete_seq(4);
    $ali->delete_seq(2);
    my $filtered_ali  = $list->filtered_ali($ali);
    is_deeply [ map { $_->full_id }  $filtered_ali->all_seq_ids ],
        \@filt_ids_miss, 'got expected filtered ids in spite of missing ids';
    my $reordered_ali = $list->reordered_ali($ali);
    is_deeply [ map { $_->full_id } $reordered_ali->all_seq_ids ],
        \@reor_ids_miss, 'got expected reordered ids in spite of missing ids';
}

my @exp_std_ids = (
    'Desulfotomaculum gibsoniae_767817@357041591',
    'Solibacillus silvestris_1002809@327439945',
    'Curvibacter putative_667019@260221396',
    'Acholeplasma laidlawii_441768@162448101',
    'Lysinibacillus fusiformis_714961@299534964',
);

{
    my $infile = file('test', 'AhHMA4_5_filtered.ali');
    my $ali = Bio::MUST::Core::Ali->load($infile);
    my $list = $ali->std_list;
    my $alpha = $ali->alphabetical_list;
    is_deeply $list->ids, \@exp_std_ids, 'got expected standard list';
    is_deeply $alpha->ids, \@exp_ids, 'got expected alphabetical list';
}

my @exp_lists = (
    [ 56,  [ 'seq1' ], [ 'seq2', 'seq3', 'seq4', 'seq5', 'seq6', 'seq7', 'seq8', 'seq9', 'seq10' ] ],
    [ 52,  [ 'seq1', 'seq2', 'seq4', 'seq9' ], [ 'seq3', 'seq5', 'seq6', 'seq7', 'seq8', 'seq10' ] ],
    [ 45,  [ 'seq1', 'seq2', 'seq3', 'seq4', 'seq6', 'seq7', 'seq8', 'seq9' ], [ 'seq5', 'seq10' ] ],
    [ 0.9, [ 'seq1', 'seq2', 'seq4', 'seq9' ], [ 'seq3', 'seq5', 'seq6', 'seq7', 'seq8', 'seq10' ] ],
    [ 0.6, [ 'seq1', 'seq2', 'seq3', 'seq4', 'seq5', 'seq6', 'seq7', 'seq8', 'seq9', 'seq10' ], [] ],
);

{
    for my $exp_row (@exp_lists) {
        my $infile = file('test', 'complete.ali');
        my $ali = Bio::MUST::Core::Ali->load($infile);

        my $min_res = $exp_row->[0];
        my $list = $ali->complete_seq_list($min_res);
        is_deeply $list->ids, $exp_row->[1],
            "got expected list of complete seqs at $min_res";
        my $negative = $list->negative_list($ali);
        is_deeply $negative->ids, $exp_row->[2],
            "got expected negative list at $min_res";

    }
}

done_testing;
