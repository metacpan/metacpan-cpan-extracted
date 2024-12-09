#!/usr/bin/env perl

use Test::Most;
use Test::Files;

use autodie;
use feature qw(say);

use List::AllUtils qw(shuffle);
use Path::Class qw(file);

use Bio::MUST::Core;

my $class = 'Bio::MUST::Core::Ali::Stash';

{
    my $infile = file('test', 'stash.fasta');
    my $db = $class->load($infile);
    cmp_ok $db->filename, 'eq', $infile, "got expected filename: $infile";
    cmp_ok $db->count_seqs, '==', 15, 'got expected number of seqs';

    cmp_ok $db->get_seq_with_id('gi|451783224|2520-2584 definition')->seq,
        'eq', 'LSDWLGLSKDKIELNRDILDYGMNSIMVMK', 'got expected seq with id';

    ok !defined $db->get_seq_with_id('missing-id'),
        'got expected undef for missing seq';
}

{
    my $infile = file('test', 'stash.fasta');
    my $db = $class->load($infile, { truncate_ids => 1 } );
    cmp_ok $db->get_seq_with_id('gi|451783224|2520-2584')->seq, 'eq',
        'LSDWLGLSKDKIELNRDILDYGMNSIMVMK', 'got expected seq with truncated id';

    my $list = Bio::MUST::Core::IdList->new(
        ids => [ qw(gi|451783223|2559-2624 gi|451783224|2520-2584
                  gi|451783225|2499-2556 gi|451783225|2614-2673) ]
    );

    my $reordered_ali = $list->reordered_ali($db);
    cmp_ok $reordered_ali->count_seqs, '==', 4,
        'got expected number of extracted seqs';
}

done_testing;
