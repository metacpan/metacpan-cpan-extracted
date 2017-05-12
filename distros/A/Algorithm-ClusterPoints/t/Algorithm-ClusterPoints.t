#!/usr/bin/perl

use Test::More tests => 252;
use Algorithm::ClusterPoints;

use Data::Dumper;

sub some_partition;

my $out;

for my $dim (2, 3, 5) {
    for my $n (1, 5, 30, 100) {
        my @points = map rand, 1..$n*$dim;
        my $clp = Algorithm::ClusterPoints->new(radius => 1, ordered => 1, minimum_size => 1, dimension => $dim);
        $clp->add_points(@points);
        for my $ir (1, 10, 100) {
            my $r = 1/$ir;
            $clp->radius($r);
            for my $min_size (1, 2, 10) {
                for (1..(($dim-1) || 1)) {
                    $clp->dimensional_groups(some_partition($dim));
                    my @clusters = $clp->clusters_ix;
                    my @bfclusters = $clp->brute_force_clusters_ix;
                    # print STDERR Data::Dumper->Dump([$r, \@clusters, \@bfclusters], [qw(r clusters bfclusters)]);
                    unless (is_deeply(\@clusters, \@bfclusters, "dim: $dim, n: $n, ir: $ir")) {
                        diag "dimensional groups: ". Algorithm::ClusterPoints::_hypercylinder_id($clp->dimensional_groups);
                        unless ($out) {
                            open $out, '> /tmp/acp.out' or next;
                            require Data::Dumper;
                        }
                        print $out Data::Dumper->Dump([$clp, \@bfclusters], [qw($clp $bfc)]);
                    }
                }
            }
        }
    }
}

sub some_partition {
    my $n = shift;
    my @part;
    for my $ix (0..$n-1) {
        push @{$part[(@part+1) * rand] ||= []}, $ix;
    }
    return @part;
}
