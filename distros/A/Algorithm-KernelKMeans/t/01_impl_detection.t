use strict;
use warnings;

use ExtUtils::testlib;
use Test::More;

use Algorithm::KernelKMeans;

my $impl = $Algorithm::KernelKMeans::IMPLEMENTATION;
like $impl, qr/^PP$|^XS$/;

my $impl_class = "Algorithm::KernelKMeans::$impl";
isa_ok 'Algorithm::KernelKMeans', $impl_class;

done_testing;
