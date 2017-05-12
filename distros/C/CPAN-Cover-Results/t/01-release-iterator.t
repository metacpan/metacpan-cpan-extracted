#! perl

use strict;
use warnings;
use Test::More 0.88 tests => 3;
use CPAN::Cover::Results;

my $ccr = CPAN::Cover::Results->new(path => 't/cpancover-extract.json');
ok(defined($ccr), "constructor should return an object");

my $iterator = $ccr->release_iterator;
ok(defined($iterator), "iterator should return an object");

my $expected = <<'END_EXPECTED';
AI-Genetic-Pro-Macromolecule|version=0.09280.0_001|branch=undef|condition=undef|pod=undef|stmt=91.67|sub=100.00|total=93.75
Graph|version=0.96|branch=74.89|condition=66.27|pod=87.15|stmt=89.97|sub=92.20|total=84.27
Graph|version=0.96_01|branch=77.56|condition=67.61|pod=87.15|stmt=91.56|sub=94.98|total=86.12
Module-Path|version=0.13|branch=64.29|condition=33.33|pod=0.00|stmt=93.75|sub=100.00|total=82.46
Module-Path|version=0.14|branch=64.29|condition=33.33|pod=0.00|stmt=93.75|sub=100.00|total=82.46
END_EXPECTED

my $string = '';

while (my $release = $iterator->next) {
    $string .= sprintf("%s|version=%s|branch=%s|condition=%s|pod=%s|stmt=%s|sub=%s|total=%s\n",
                       $release->distname,
                       $release->version || 'undef',
                       $release->branch || 'undef',
                       $release->condition || 'undef',
                       $release->pod || 'undef',
                       $release->statement || 'undef',
                       $release->subroutine || 'undef',
                       $release->total || 'undef'
                      );
}
is($string, $expected, "check that we got the expected info");
