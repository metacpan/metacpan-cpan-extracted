use strict;
use warnings;
use Algorithm::FuzzyCmeans;
use Algorithm::FuzzyCmeans::Distance::Cosine;
use Algorithm::FuzzyCmeans::Distance::Euclid;
use Test::More tests => 5;

my $fcm = Algorithm::FuzzyCmeans->new;
can_ok($fcm, 'new');
can_ok($fcm, 'add_document');
can_ok($fcm, 'do_clustering');

my $cos = Algorithm::FuzzyCmeans::Distance::Cosine->new;
can_ok($cos, 'distance');
my $ecl = Algorithm::FuzzyCmeans::Distance::Euclid->new;
can_ok($ecl, 'distance');
