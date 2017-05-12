use strict;
use warnings;
use Algorithm::Kmeanspp;
use Test::More tests => 314;

use constant NUM_DOCUMENT => 10;
use constant NUM_KEY      => 30;
use constant NUM_CLUSTER  => 3;
use constant NUM_ITER     => 10;

my $kmp = Algorithm::Kmeanspp->new;

foreach my $id (0 .. NUM_DOCUMENT-1) {
    my %vector;
    foreach my $key (0 .. NUM_KEY-1) {
        $vector{$key} = rand(1);
    }
    $kmp->add_document($id, \%vector);

    # check add_document
    while (my ($key, $val) = each %vector) {
        is($kmp->vectors->{$id}{$key}, $val);
    }
}
is(scalar(keys %{ $kmp->vectors }), NUM_DOCUMENT);

$kmp->do_clustering(NUM_CLUSTER, NUM_ITER);

# check clusters
my $clusters = $kmp->clusters;
is(scalar(@{ $clusters }), NUM_CLUSTER);
my %check;
my $sum_id = 0;
foreach my $cluster (@{ $clusters }) {
    foreach my $id (@{ $cluster }) {
        ok(!$check{$id});
        $check{$id} = 1;
        $sum_id++;
    }
}
is($sum_id, NUM_DOCUMENT);

# check the number of centroids
is(scalar(@{ $kmp->centroids }), NUM_CLUSTER);
