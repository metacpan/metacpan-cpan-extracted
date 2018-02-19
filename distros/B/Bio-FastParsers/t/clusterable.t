#!/usr/bin/env perl

use Test::Most;

use autodie;
use feature qw(say);

use Path::Class qw(file);
use Tie::IxHash;
use Try::Tiny;

use Bio::FastParsers;


# perl -nle 'if (m/Cluster (\d+)/) { $cluster = $1; next } ($id,$type) = m/>(\S+)\.{3} (\*|at)/; $hash{$cluster}{repr} = $id if $type eq q{*}; push @{$hash{$cluster}{memb}}, $id if $type eq q{at}; END{ for $cluster (sort { $a <=> $b } keys %hash) { print $hash{$cluster}{repr} . q{: } . join q{ }, @{$hash{$cluster}{memb}}; } }' cdHit.out.clstr > cdHit.out.groups

# perl -MSort::Naturally -nle 'my ($id, $member_str) = split ": "; my @members = split q{ }, $member_str; $hash{$id} = \@members; END{ @list = sort { scalar @{$hash{$b}} <=> scalar @{$hash{$a}} || ncmp($a, $b) } keys %hash; print join "\n", @list }' cdHit.out.groups > cdHit.out.ids

# for f in `cat cdHit.out.ids`; do grep $f cdHit.out.groups ; done

check_clusters(
    'Bio::FastParsers::CdHit', {
        infile   => file('test', 'cdHit.out.clstr'),
        expfile1 => file('test', 'cdHit.out.groups'),
        expfile2 => file('test', 'cdHit.out.ids'),
        idmfile  => file('test', 'cdHit.out.clstr.idm'),
    }
);

# perl -MTie::IxHash -anle 'BEGIN{ tie %hash, 'Tie::IxHash' } push @{ $hash{$F[8]} }, () if $F[0] eq 'C'; push @{ $hash{$F[9]} }, $F[8] if $F[0] eq 'H'; END{ while (($repr, $members) = each %hash) { print $repr . q{: } . join q{ }, @$members } }' uclust.uc > uclust.uc.groups

# perl -MSort::Naturally -nle 'my ($id, $member_str) = split ": "; my @members = split q{ }, $member_str; $hash{$id} = \@members; END{ @list = sort { scalar @{$hash{$b}} <=> scalar @{$hash{$a}} || ncmp($a, $b) } keys %hash; print join "\n", @list }' uclust.uc.groups > uclust.uc.ids

check_clusters(
    'Bio::FastParsers::Uclust', {
        infile   => file('test', 'uclust.uc'),
        expfile1 => file('test', 'uclust.uc.groups'),
        expfile2 => file('test', 'uclust.uc.ids'),
        idmfile  => file('test', 'uclust.uc.idm'),
    }
);


sub check_clusters {
    my $class = shift;
    my $args  = shift // {};

    my ($infile, $expfile1, $expfile2, $idmfile)
        = @{$args}{ qw(infile expfile1 expfile2 idmfile) };

    explain $class;

    tie my %exp_members_for, 'Tie::IxHash';

    open my $in, '<', $expfile1;
    while (my $line = <$in>) {
        chomp $line;
        my ($repr, $memb_str) = $line =~ m/(\S+) \s* : \s* (.*)/xms;
        $exp_members_for{$repr} = [ split /\s+/, $memb_str ];
    }

    my @exp_ids = $expfile2->slurp( chomp => 1 );

    my $report = $class->new( file => $infile );

    is_deeply [ $report->all_representatives ], [ keys %exp_members_for ],
        'got expected list of representatives';
    is_deeply [ $report->all_representatives_by_cluster_size ], \@exp_ids,
        'got expected list of representatives by decreasing cluster size';

    for my $repr ( $report->all_representatives ) {
        is_deeply $report->members_for($repr), $exp_members_for{$repr},
            "got expected list of members for representative: $repr";
    }

    my $bmc = try   { require Bio::MUST::Core }
              catch { return }
    ;

    SKIP: {
        skip 'due to Bio::MUST::Core not installed', 1
            unless $bmc;

        my $exp_mapper = Bio::MUST::Core::IdMapper->load($idmfile);
        my $got_mapper = $report->clust_mapper(':');
        is_deeply [ $got_mapper->all_long_ids ], [ $exp_mapper->all_long_ids ],
            'got expected IdMapper';
    }

    return;
}

done_testing;
