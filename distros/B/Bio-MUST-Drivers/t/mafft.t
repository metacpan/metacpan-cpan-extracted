#!/usr/bin/env perl

use Test::Most;
use Test::Files;

use autodie;
use feature qw(say);

use List::AllUtils;
use Module::Runtime qw(use_module);
use Path::Class qw(file);

use Bio::MUST::Core;
use Bio::MUST::Drivers::Mafft;


say <<'EOT';
Note: tests designed for:
- MAFFT v7.453 (2019/Nov/8)
- MAFFT v7.475 (2020/Nov/23)
- MAFFT v7.526 (2024/Apr/26)
EOT

my $class = 'Bio::MUST::Drivers::Mafft';

# Note: provisioning system is not enabled to help tests to pass on CPANTS
my $app = use_module('Bio::MUST::Provision::Mafft')->new;
unless ( $app->condition ) {
    plan skip_all => <<"EOT";
skipped all MAFFT tests!
If you want to use this module you need to install the MAFFT executable v7.313 or greater:
https://mafft.cbrc.jp/alignment/software/
If you --force installation, I will eventually try to install MAFFT with brew:
https://brew.sh/
EOT
}
# TODO: make provisioning system more sophisticate by handling versioning?
# ( my $version = qx{mafft --version 2>&1} // 'v1.0.0' ) =~ s/^(\S+).*/$1/xms;
# use version;
# unless ( version->parse($version) >= version->parse(7.313) ) {

{
    # align_all
    my $file = file('test', 'seq_in1.fasta');
    my $maf = $class->new( file => $file );
    my $align_all = $maf->align_all;
    my $exp_file = file('test', 'seq_out1_gap_mafft.fasta');
    my $exp_align = Bio::MUST::Core::Ali->load($exp_file);

    my @got_align_seqs     = $align_all->all_seqs;
    my @exp_align_seqs     = $exp_align->all_seqs;
    my @got_align_seq_ids  = $align_all->all_seq_ids;
    my @exp_align_seq_ids  = $exp_align->all_seq_ids;

    is_deeply $align_all->count_seqs, $exp_align->count_seqs,
        'good number of seqs';

    is_deeply \@got_align_seqs, \@exp_align_seqs,
        'sequences correctly aligned for align_all';

    is_deeply \@got_align_seq_ids, \@exp_align_seq_ids,
        'ids correctly written for align_all';
}

{
    # profile2profile with error (not monophyletic)
    my $aligned_file = file('test', 'seq_out2_mafft.fasta');
    my $profile = file('test', 'seq_out1_mafft.fasta');
    my $maf = $class->new( file => $aligned_file );
    my $profile2profile = $maf->profile2profile($profile);

    is $profile2profile, undef,
        'return correctly undef when profile2profile not aligned';
}

{
    # profile2profile
    my $aligned_file = file('test', 'seq_out1_mafft.fasta');
    my $maf = $class->new( file => $aligned_file );
    my $profile = file('test', 'seq_out2_mafft.fasta');
    my $profile2profile = $maf->profile2profile($profile);
    my $exp_file = file('test', 'seq_profiles_mafft.fasta');
    my $exp_profiles = Bio::MUST::Core::Ali->load($exp_file);

    my @got_p2p_seqs       = $profile2profile->all_seqs;
    my @exp_p2p_seqs       = $exp_profiles->all_seqs;
    my @got_p2p_seq_ids    = $profile2profile->all_seq_ids;
    my @exp_p2p_seq_ids    = $exp_profiles->all_seq_ids;

    is_deeply $profile2profile->count_seqs, $exp_profiles->count_seqs,
        'good number of seqs for profile2profile';

    is_deeply \@got_p2p_seqs, \@exp_p2p_seqs,
        'sequences correctly aligned for profile2profile';

    is_deeply \@got_p2p_seq_ids, \@exp_p2p_seq_ids,
        'ids correctly written for profile2profile';
}

{
    # seqs2profile
    my $file2align = file('test', 'seq_in2.fasta');
    my $profile = file('test', 'seq_out1_mafft.fasta');

    # Note: long and fragments alignments are less good here but not important
    for my $opt ( q{}, 'long', 'fragments' ) {
        my $maf = $class->new( file => $file2align );
        my $seqs2profile
            = $maf->seqs2profile($profile, $opt ? { "--$opt" => undef } : () );
        my $exp_file = file('test', "${opt}seq_profile_out.fasta");
        my $exp_new_profile = Bio::MUST::Core::Ali->load($exp_file);

        my @got_seqs2p_seqs    = $seqs2profile->all_seqs;
        my @exp_seqs2p_seqs    = $exp_new_profile->all_seqs;
        my @got_seqs2p_seq_ids = $seqs2profile->all_seq_ids;
        my @exp_seqs2p_seq_ids = $exp_new_profile->all_seq_ids;

        is_deeply $seqs2profile->count_seqs, $exp_new_profile->count_seqs,
            "good number of seqs for seqs2profile with: $opt";

        is_deeply \@got_seqs2p_seqs, \@exp_seqs2p_seqs,
            "sequences correctly aligned for seqs2profile with: $opt";

        is_deeply \@got_seqs2p_seq_ids, \@exp_seqs2p_seq_ids,
            "ids correctly written for seqs2profile with: $opt";
    }
}

done_testing;
