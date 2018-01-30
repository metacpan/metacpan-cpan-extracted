#!/usr/bin/env perl

use Test::Most;
use Test::Files;

use autodie;
use feature qw(say);

use List::AllUtils qw(shuffle);
use Path::Class qw(file);

use Bio::MUST::Core;

my $class = 'Bio::MUST::Core::Ali::Temporary';

my $filename;

{
    my $filepath = file('test', 'ali_with_qm.ali');
    my $temp = $class->new( seqs => $filepath );
    $filename = $temp->filename;
    compare_ok($filename, file('test', 'ali_with_qm_temp.fasta'),
        "wrote expected Ali::Temporary from bare string: $filename");
}
ok(!-e $filename, '... and it got deleted as expected!');

{
    my $temp = $class->new( seqs => file('test', 'ali_with_qm.ali') );
    $filename = $temp->filename;
    compare_ok($filename, file('test', 'ali_with_qm_temp.fasta'),
        "wrote expected Ali::Temporary from Path::Class::File: $filename");
}
ok(!-e $filename, '... and it got deleted as expected!');

{
    my $ali = Bio::MUST::Core::Ali->load(file('test', 'ali_with_qm.ali'));
    my $temp = $class->new( seqs => $ali->seqs );
    $filename = $temp->filename;
    compare_ok($filename, file('test', 'ali_with_qm_temp.fasta'),
        "wrote expected Ali::Temporary from ArrayRef[Seq]: $filename");

    my @exp_long_ids = map { $_->full_id } $ali->all_seq_ids;
    my @exp_abbr_ids = map { "seq$_" } 1..@exp_long_ids;
    my @order = shuffle (0..$#exp_long_ids);
    for my $i (@order) {
        my $exp_long_id = $exp_long_ids[$i];
        my $exp_abbr_id = $exp_abbr_ids[$i];

        my $long_id = $temp->long_id_for($exp_abbr_id);
        my $abbr_id = $temp->abbr_id_for($exp_long_id);

        is $exp_long_id, $long_id, "got expected long_id for index $i";
        is $exp_abbr_id, $abbr_id, "got expected abbr_id for index $i";
    }

    is_deeply [ $ali->$_ ], [ $temp->$_ ],
        "got expected result from delegated method: $_"
            for qw(all_seq_ids has_uniq_ids is_protein all_seqs count_seqs);
}
ok(!-e $filename, '... and it got deleted as expected!');

# TODO: expand this file to other coercions?

{
    my $filepath = file('test', 'ali_with_qm.ali');
    my $temp = $class->new( seqs => $filepath, args => { degap => 0 } );
    $filename = $temp->filename;
    compare_ok($filename, file('test', 'ali_with_qm_temp_gaps.fasta'),
        "wrote expected Ali::Temporary preserving gaps: $filename");
}
ok(!-e $filename, '... and it got deleted as expected!');

{
    my $filepath = file('test', 'ali_with_qm.ali');
    my $temp = $class->new(
        seqs => $filepath,
        args => { degap => 0, persistent => 1 }
    );
    $filename = $temp->filename;
    compare_ok($filename, file('test', 'ali_with_qm_temp_gaps.fasta'),
        "wrote expected Ali::Temporary preserving gaps: $filename");
}
ok(-e $filename, '... and it persisted as expected!');
unlink $filename;

done_testing;
