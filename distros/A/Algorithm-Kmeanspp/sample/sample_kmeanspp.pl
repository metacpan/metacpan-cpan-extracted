#!/usr/bin/perl
#
# Sample program of Algorithm::Kmeanspp
#

use strict;
use warnings;
use FindBin::libs;
use Algorithm::Kmeanspp;

my $kmp = Algorithm::Kmeanspp->new;

# read input documents
# format: id \t key1 \t val1 \t key2 \t val2 \t ...\n
while (my $line = <DATA>) {
    chomp $line;
    my @arr = split /\t/, $line;
    my $id = shift @arr;
    my %vector = @arr;
    $kmp->add_document($id, \%vector);
}

my $num_cluster = 3;
my $num_iter    = 20;
$kmp->do_clustering($num_cluster, $num_iter);

print "Clusters:\n";
foreach my $cluster (@{ $kmp->clusters }) {
    print join "\t", sort { $a cmp $b } @{ $cluster };
    print "\n";
}

print "\n";
print "Cluster centroids:\n";
foreach my $centroids (@{ $kmp->centroids }) {
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
