#!/usr/bin/perl
#
# Sample program of Algorithm::FuzzyCmeans
#

use strict;
use warnings;
use FindBin::libs;
use Algorithm::FuzzyCmeans;

my $fcm = Algorithm::FuzzyCmeans->new(
    distance_class => 'Algorithm::FuzzyCmeans::Distance::Cosine',
    m              => 2,
);

# read input documents
# format: id \t key1 \t val1 \t key2 \t val2 \t ...\n
while (my $line = <DATA>) {
    chomp $line;
    my @arr = split /\t/, $line;
    my $id = shift @arr;
    my %vector = @arr;
    $fcm->add_document($id, \%vector);
}

my $num_cluster = 3;
my $num_iter    = 20;
$fcm->do_clustering($num_cluster, $num_iter);

print "Clustering result:\n";
foreach my $id (sort { $a cmp $b } keys %{ $fcm->memberships }) {
    printf "%s\t%s\n", $id,
        join "\t", map { sprintf "%.4f", $_ } @{ $fcm->memberships->{$id} };
}

print "\n";
print "Cluster centroids:\n";
foreach my $centroids (@{ $fcm->centroids }) {
    print join "\t", map {
        sprintf "%s:%.4f", $_, $centroids->{$_}
    } keys %{ $centroids };
    print "\n";
}

__DATA__
Alex	Pop	10	R&B	6	Rock	4
Bob	Jazz	8	Reggae	9
Dave	Classic	4	World	4
Ted	Jazz	9	Metal	2	Reggae	6
Fred	Pop	4	Rock	3	Hip-hop	3
Sam	Classic	8	Rock	1
