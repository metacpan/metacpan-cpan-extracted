use strict;
use warnings;
use Algorithm::Kmeanspp;
use Test::More tests => 3;

my $kmp = Algorithm::Kmeanspp->new;
can_ok($kmp, 'new');
can_ok($kmp, 'add_document');
can_ok($kmp, 'do_clustering');
