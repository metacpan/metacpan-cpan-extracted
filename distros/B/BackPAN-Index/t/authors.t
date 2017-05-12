#!perl

use strict;
use warnings;

use lib 't/lib';

use TestUtils;
use Test::More;

my $b = new_backpan;

my $dist = $b->dist("Moose");
my %want = map { $_ => 1 } qw(DROLSKY FLORA GRODITI SARTAK STEVAN);
for my $author ($dist->authors) {
    delete $want{$author};
}
is_deeply \%want, {};

done_testing;
