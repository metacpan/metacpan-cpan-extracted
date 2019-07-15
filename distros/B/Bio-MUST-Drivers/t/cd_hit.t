#!/usr/bin/env perl

use Test::Most;

use autodie;
use feature qw(say);

use List::AllUtils;
use Module::Runtime qw(use_module);
use Path::Class qw(file);
use Tie::IxHash;

use Bio::MUST::Core;
use Bio::MUST::Drivers::CdHit;

my $class = 'Bio::MUST::Drivers::CdHit';


# Note: provisioning system is not enabled to help tests to pass on CPANTS
my $app = use_module('Bio::MUST::Provision::CdHit')->new;
unless ( $app->condition ) {
    plan skip_all => <<"EOT";
skipped all CD-HIT tests!
If you want to use this module you need to install the CD-HIT executable:
https://github.com/weizhongli/cdhit
If you --force installation, I will eventually try to install CD-HIT with brew:
https://brew.sh/
EOT
}
# TODO: fix this as CD-HIT formula currently fails on OS X Mojave
#       This can be done with a --build-from-source option of brew

# expected members for
my $exp_clstr_file = file('test', 'cdHit.out.groups');
open my $in, '<', $exp_clstr_file;

tie my %exp_members_for, 'Tie::IxHash';
while (my $line = <$in>) {
    chomp $line;
    my ($repr, $memb_str) = $line =~ m/(\S+) \s* : \s* (.*)/xms;
    $exp_members_for{$repr} = [ split /\s+/, $memb_str ];
}

# expected representative seqs
my $exp_repr_seq_file = file('test', 'cdHit.out.fasta');
my $exp_repr_seqs = Bio::MUST::Core::Ali->load($exp_repr_seq_file);
my %exp_repr_for = (
    '1053365|ASA38802.1' => '360866|ASA39338.1',
    '1053365|ASA38803.1' => '360866|ASA39339.1',
    '1053365|ASA38804.1' => '360866|ASA39340.1',
    '1053365|ASA38805.1' => '360866|ASA39341.1',
    '1053365|ASA38806.1' => '360866|ASA39342.1',
    '1053365|ASA38809.1' => '360866|ASA39345.1',
    '1053365|ASA38810.1' => '360866|ASA39346.1',
    '1715899|ASA38533.1' => '360866|ASA39338.1',
    '1715899|ASA38534.1' => '360866|ASA39339.1',
    '1715900|ASA38624.1' => '360866|ASA39339.1',
    '2010898|ASA38355.1' => '360866|ASA39339.1'
);

# call cd-hit
my $cdh = $class->new( seqs => file('test', 'cdHit.in.fasta') );

# cluster members
is_deeply [ $cdh->all_cluster_names ],
    [ keys %exp_members_for ],
    'got expected list of representative ids'
;
for my $repr ( $cdh->all_cluster_names ) {
    is_deeply [ map { $_->full_id } @{ $cdh->seq_ids_for($repr) } ],
        $exp_members_for{$repr},
        "got expected list of member SeqIds for representative: $repr"
    ;
}
is_deeply [ map { [ map { $_->full_id } @{$_} ] } $cdh->all_cluster_seq_ids ],
    [ values %exp_members_for ],
    'got expected SeqIds for cluster members'
;

# representative Seqs
is_deeply $cdh->count_representatives,
    $exp_repr_seqs->count_seqs,
    'got expected number of representatives (clusters)'
;
is_deeply [ $cdh->all_representatives ],
    [ $exp_repr_seqs->all_seqs ],
    'got expected list of representative Seqs'
;
for my $id ( $cdh->all_cluster_names ) {
    is_deeply $cdh->get_representative_with_id($id)->seq,
        $exp_repr_seqs->get_seq_with_id($id)->seq,
        "got expected Seq for representative: $id"
    ;
}

# reverse hash (representative_for)
is_deeply [ sort $cdh->all_member_names ],
    [ sort map { @{ $exp_members_for{$_} } } keys %exp_members_for ],
    'got expected list of member ids'
;
for my $memb ( keys %exp_repr_for ) {
    is_deeply $cdh->representative_for($memb)->full_id,
        $exp_repr_for{$memb},
        "got expected representative id for member: $memb"
    ;
}

# cd-hit-est
my $cdh_est = $class->new( seqs => file('test', 'seqs4cap3.fasta') );
cmp_ok $cdh_est->all_cluster_seq_ids, '>', 0,
    'correctly launched cd-hit-est for nt infile';

done_testing;
