#!/usr/bin/env perl

use Test::Most;
use Test::Files;

use autodie;
use feature qw(say);

use List::AllUtils;
use Module::Runtime qw(use_module);
use Path::Class qw(file);

use Bio::MUST::Core;
use Bio::MUST::Drivers::ClustalO;

my $class = 'Bio::MUST::Drivers::ClustalO';


# Note: provisioning system is not enabled to help tests to pass on CPANTS
my $app = use_module('Bio::MUST::Provision::ClustalO')->new;
unless ( $app->condition ) {
    plan skip_all => <<"EOT";
skipped all ClustalO tests!
If you want to use this module you need to install the ClustalO executable:
http://www.clustal.org/omega/
If you --force installation, I will eventually try to install ClustalO with brew:
https://brew.sh/
EOT
}

# align_all
my $file = file('test', 'seq_in1.fasta');
my $clu = $class->new( file => $file );
my $align_all = $clu->align_all;
my $exp_file = file('test', 'seq_out1_short_clustal.fasta');
my $exp_align = Bio::MUST::Core::Ali->load($exp_file);

my @got_align_seqs      = $align_all->all_seqs;
my @exp_align_seqs      = $exp_align->all_seqs;
my @got_align_seq_ids   = $align_all->all_seq_ids;
my @exp_align_seq_ids   = $exp_align->all_seq_ids;

is_deeply $align_all->count_seqs, $exp_align->count_seqs,
    'good number of seqs';

is_deeply \@got_align_seqs, \@exp_align_seqs,
    'sequences correctly aligned for align_all';

is_deeply \@got_align_seq_ids, \@exp_align_seq_ids,
    'ids correctly written for align_all';

# seqs2profile
my $file2align = file('test', 'seq_in2.fasta');
my $profile = file('test', 'seq_out1_clustal.fasta');
my $clu2 = $class->new( file => $file2align );
my $seqs2profile = $clu2->seqs2profile($profile);
my $exp_file2 = file('test', 'seqs_profile_out_clustal.fasta');
my $exp_new_profile = Bio::MUST::Core::Ali->load($exp_file2);

my @got_seqs2p_seqs     = $seqs2profile->all_seqs;
my @exp_seqs2p_seqs     = $exp_new_profile->all_seqs;
my @got_seqs2p_seq_ids  = $seqs2profile->all_seq_ids;
my @exp_seqs2p_seq_ids  = $exp_new_profile->all_seq_ids;

is_deeply $seqs2profile->count_seqs, $exp_new_profile->count_seqs,
    'good number of seqs for seqs2profile';

is_deeply \@got_seqs2p_seqs, \@exp_seqs2p_seqs,
    'sequences correctly aligned for seqs2profile';

is_deeply \@got_seqs2p_seq_ids, \@exp_seqs2p_seq_ids,
    'ids correctly written for seqs2profile';

#seqs2profile with two profiles
my $aligned_file = file('test', 'seq_out2_clustal.fasta');
my $clu3 = $class->new( file => $aligned_file );
my $seqs2profile2 = $clu3->seqs2profile($profile);
my $exp_file4 = file('test', 'seqs_2profile_out_clustal.fasta');
my $exp_new_profile2 = Bio::MUST::Core::Ali->load($exp_file4);

my @got_seqs2p2_seqs    = $seqs2profile2->all_seqs;
my @exp_seqs2p2_seqs    = $exp_new_profile2->all_seqs;
my @got_seqs2p2_seq_ids = $seqs2profile2->all_seq_ids;
my @exp_seqs2p2_seq_ids = $exp_new_profile2->all_seq_ids;

is_deeply $seqs2profile2->count_seqs, $exp_new_profile2->count_seqs,
    'good number of seqs for seqs2profile with two profile files';

is_deeply \@got_seqs2p2_seqs, \@exp_seqs2p2_seqs,
    'sequences correctly aligned for seqs2profile with two profile files';

is_deeply \@got_seqs2p2_seq_ids, \@exp_seqs2p2_seq_ids,
    'ids correctly written for seqs2profile with two profile files';

# profile2profile
my $clu4 = $class->new( file => $aligned_file );
my $profile2profile = $clu4->profile2profile($profile);
my $exp_file3 = file('test', 'seq_profiles2_clustal.fasta');
my $exp_profiles = Bio::MUST::Core::Ali->load($exp_file3);

my @got_p2p_seqs        = $profile2profile->all_seqs;
my @exp_p2p_seqs        = $exp_profiles->all_seqs;
my @got_p2p_seq_ids     = $profile2profile->all_seq_ids;
my @exp_p2p_seq_ids     = $exp_profiles->all_seq_ids;

is_deeply $profile2profile->count_seqs, $exp_profiles->count_seqs,
    'good number of seqs for profile2profile';

is_deeply \@got_p2p_seqs, \@exp_p2p_seqs,
    'sequences correctly aligned for profile2profile';

is_deeply \@got_p2p_seq_ids, \@exp_p2p_seq_ids,
    'ids correctly written for profile2profile';

done_testing;
