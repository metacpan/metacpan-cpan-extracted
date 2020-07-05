#!/usr/bin/env perl

use Test::Most;
use Test::Files;

use autodie;
use feature qw(say);

use Smart::Comments '###';

use Path::Class qw(file);

use Bio::MUST::Apps::TwoScalp;
my $ali = 'Bio::MUST::Core::Ali';

# skip all two-scalp.pl tests unless blastp is available in the $PATH
unless ( qx{which blastp} ) {
    plan skip_all => <<"EOT";
skipped all two-scalp.pl tests!
If you want to use this program you need to install NCBI BLAST+ executables:
ftp://ftp.ncbi.nlm.nih.gov/blast/executables/blast+/LATEST/
EOT
}

{
    my $class = 'Bio::MUST::Apps::TwoScalp::Seq2Seq';

    $class->new(
        ali => file('test', 'PTHR22663.ali'),
        out_suffix   => '-my-ts-s2s',
        coverage_mul => 1.01,
        single_hsp   => 0,
    );

    compare_ok(
        file('test', 'PTHR22663-my-ts-s2s.ali'),
        file('test', 'PTHR22663-ts-s2s.ali'),
            'wrote expected Ali for: PTHR22663'
    );
}

{
    my $class = 'Bio::MUST::Apps::TwoScalp::Profile2Profile';

    my $infile1 = file('test', 'seq_out1_mafft.fasta');
    my $infile2 = file('test', 'seq_out2_mafft.fasta');
    
    my $align = $class->new( file1 => $infile1, file2 => $infile2 );

    my @got_seqs_maf = $align->all_seqs;
    my @got_seq_ids_maf = $align->all_seq_ids;
    my $exp_mafft = file('test', 'seq_profiles_mafft.fasta');
    my $exp_ali_mafft = $ali->load($exp_mafft);
    my @exp_seqs_maf = $exp_ali_mafft->all_seqs;
    my @exp_seq_ids_maf = $exp_ali_mafft->all_seq_ids;
    my $align2 = $class->new( file1 => $infile2, file2 => $infile1 );
    my @got_seqs = $align2->all_seqs;
    my @got_seq_ids = $align2->all_seq_ids;
    my $exp_clustal = file('test', 'seq_profiles2_clustal.fasta');
    my $exp_ali_clustal = $ali->load($exp_clustal);
    my @exp_seqs = $exp_ali_clustal->all_seqs;
    my @exp_seq_ids = $exp_ali_clustal->all_seq_ids;
    
    is_deeply \@got_seqs_maf, \@exp_seqs_maf,
        "profiles correctly aligned with mafft";
    is_deeply \@got_seq_ids_maf, \@exp_seq_ids_maf,
        "ids correctly written: mafft";
    is_deeply \@got_seqs, \@exp_seqs,
        "profiles correctly aligned with clustalo";
    is_deeply \@got_seq_ids, \@exp_seq_ids,
        "ids correctly written: clustalo";
}

{
    my $class = 'Bio::MUST::Apps::TwoScalp::Seqs2Profile';

    my $infile1 = file('test', 'seq_in2.fasta');
    my $infile2 = file('test', 'seq_out1_mafft.fasta');
    
    my $align = $class->new( file1 => $infile1, file2 => $infile2 );
    
    my @got_seqs_maf = $align->all_seqs;
    my @got_seq_ids_maf = $align->all_seq_ids;
    
    my $exp_mafft = file('test', 'seq_profile_out.fasta');
    my $exp_ali_mafft = $ali->load($exp_mafft);
    my @exp_seqs_maf = $exp_ali_mafft->all_seqs;
    my @exp_seq_ids_maf = $exp_ali_mafft->all_seq_ids;
    
    is_deeply \@got_seqs_maf, \@exp_seqs_maf,
        "sequences correctly aligned on profile with mafft";
    is_deeply \@got_seq_ids_maf, \@exp_seq_ids_maf,
        "ids correctly written: mafft";

}

{
    my $class = 'Bio::MUST::Apps::TwoScalp::AlignAll';

    my $infile1 = file('test', 'seq_in1.fasta');
    
    my $align = $class->new( file => $infile1 );
    
    my @got_seqs_maf = $align->all_seqs;
    my @got_seq_ids_maf = $align->all_seq_ids;
    
    my $exp_mafft = file('test', 'seq_out1_gap_mafft.fasta');
    my $exp_ali_mafft = $ali->load($exp_mafft);
    my @exp_seqs_maf = $exp_ali_mafft->all_seqs;
    my @exp_seq_ids_maf = $exp_ali_mafft->all_seq_ids;
    
    is_deeply \@got_seqs_maf, \@exp_seqs_maf,
        "sequences correctly aligned from scratch with mafft";
    is_deeply \@got_seq_ids_maf, \@exp_seq_ids_maf,
        "ids correctly written: mafft";

}

done_testing;
