use strict;
use warnings;
use Algorithm::FuzzyCmeans;
use Test::More tests => 313;

use constant NUM_DOCUMENT => 10;
use constant NUM_KEY      => 30;
use constant NUM_CLUSTER  => 3;
use constant NUM_ITER     => 10;

my $threshold = 0.1;
my $fcm = Algorithm::FuzzyCmeans->new(
    distance_class => 'Algorithm::FuzzyCmeans::Distance::Cosine',
    m              => 2,
);
foreach my $id (0 .. NUM_DOCUMENT-1) {
    my %vector;
    foreach my $key (0 .. NUM_KEY-1) {
        $vector{$key} = rand(1);
    }
    $fcm->add_document($id, \%vector);

    # check add_document
    while (my ($key, $val) = each %vector) {
        is($fcm->vectors->{$id}{$key}, $val);
    }
}
is(scalar(keys %{ $fcm->vectors }), NUM_DOCUMENT);

$fcm->do_clustering(NUM_CLUSTER, NUM_ITER);

# check the number of clusters
my $memberships = $fcm->memberships();
is(scalar(keys %{ $memberships }), NUM_DOCUMENT);
foreach my $membership (values %{ $memberships }) {
    is(scalar(@{ $membership }), NUM_CLUSTER);
}

# check the number of centroids
is(scalar(@{ $fcm->centroids }), NUM_CLUSTER);
