use strict;
use warnings;
use Bio::Root::Test;
use Test::Number::Delta;
use Bio::Community::IO;

use_ok($_) for qw(
    Bio::Community::Tools::Accumulator
);


my ($accumulator, $nums, @string);

my $meta1 = Bio::Community::IO->new(
   -file => test_input_file('qiime_w_no_taxo.txt'),
)->next_metacommunity;

my $meta2 = Bio::Community::IO->new(
   -file => test_input_file('gaas_compo.txt'),
)->next_metacommunity;


# Basic object

ok $accumulator = Bio::Community::Tools::Accumulator->new( ), 'Basic object';
isa_ok $accumulator, 'Bio::Community::Tools::Accumulator';
throws_ok { $accumulator->get_numbers } qr/EXCEPTION.*metacommunity/msi;


# Collector curve with observed richness

ok $accumulator = Bio::Community::Tools::Accumulator->new(
   -metacommunity   => $meta1,
   -type            => 'collector',
   -num_repetitions => 10,
   -alpha_types     => ['observed', 'menhinick'],
   -verbose         => 1,
), 'Collector curve';
ok     $nums = $accumulator->get_numbers;

is     $nums->{'observed'}->[0]->[0], 0;
is     $nums->{'observed'}->[0]->[1], 0;
is     $nums->{'observed'}->[1]->[0], 1;
cmp_ok $nums->{'observed'}->[1]->[1], '>=', 1;
cmp_ok $nums->{'observed'}->[1]->[1], '<=', 3;
is     $nums->{'observed'}->[2]->[0], 2;
is     $nums->{'observed'}->[2]->[1], 3;
is     $nums->{'observed'}->[3]->[0], 3;
is     $nums->{'observed'}->[3]->[1], 3;

is     $nums->{'menhinick'}->[0]->[0], 0;
is     $nums->{'menhinick'}->[0]->[1], 0;
is     $nums->{'menhinick'}->[1]->[0], 1;
cmp_ok $nums->{'menhinick'}->[1]->[1], '>', 0;
cmp_ok $nums->{'menhinick'}->[1]->[1], '<', 1;
is     $nums->{'menhinick'}->[2]->[0], 2;
cmp_ok $nums->{'menhinick'}->[2]->[1], '>', 0;
cmp_ok $nums->{'menhinick'}->[2]->[1], '<', 1;
is     $nums->{'menhinick'}->[3]->[0], 3;
cmp_ok $nums->{'menhinick'}->[3]->[1], '>', 0;
cmp_ok $nums->{'menhinick'}->[3]->[1], '<', 1;


SKIP: {
    test_skip(-tests => 1, -requires_module => 'Math::GSL::RNG');

    # Community with not quite integer count, e.g. 0.999999999999999

    ok $accumulator = Bio::Community::Tools::Accumulator->new(
       -metacommunity   => $meta2,
       -type            => 'rarefaction',
       -num_repetitions => 10,
    ), 'Not quite integer';
    ok     $nums = $accumulator->get_numbers;


    # Rarefaction with linear spacing and Shannon-Wiener diversity

    ok $accumulator = Bio::Community::Tools::Accumulator->new(
       -metacommunity   => $meta1,
       -type            => 'rarefaction',
       -num_ticks       => 7,
       -tick_spacing    => 'linear',
       -num_repetitions => 14,
       -alpha_types     => ['shannon'],
    ), 'Rarefaction curve';
    ok $nums = $accumulator->get_numbers;

    is     $nums->{'shannon'}->[0]->[0], 0;
    is     $nums->{'shannon'}->[0]->[1], 0;

    is     $nums->{'shannon'}->[1]->[0], 1;
    is     $nums->{'shannon'}->[1]->[1], 0;
    is     $nums->{'shannon'}->[1]->[2], 0;
    is     $nums->{'shannon'}->[1]->[3], 0;

    is     $nums->{'shannon'}->[2]->[0], 17;
    cmp_ok $nums->{'shannon'}->[2]->[1], '>', 0;
    cmp_ok $nums->{'shannon'}->[2]->[1], '<', 1;
    is     $nums->{'shannon'}->[2]->[2], 0;
    cmp_ok $nums->{'shannon'}->[2]->[3], '>', 0;
    cmp_ok $nums->{'shannon'}->[2]->[3], '<', 1;

    is     $nums->{'shannon'}->[3]->[0], 33;
    cmp_ok $nums->{'shannon'}->[3]->[1], '>', 0;
    cmp_ok $nums->{'shannon'}->[3]->[1], '<', 1;
    is     $nums->{'shannon'}->[3]->[2], 0;
    cmp_ok $nums->{'shannon'}->[3]->[3], '>', 0;
    cmp_ok $nums->{'shannon'}->[3]->[3], '<', 1;

    is     $nums->{'shannon'}->[4]->[0], 49;
    cmp_ok $nums->{'shannon'}->[4]->[1], '>', 0;
    cmp_ok $nums->{'shannon'}->[4]->[1], '<', 1;
    is     $nums->{'shannon'}->[4]->[2], 0;
    cmp_ok $nums->{'shannon'}->[4]->[3], '>', 0;
    cmp_ok $nums->{'shannon'}->[4]->[3], '<', 1;

    is     $nums->{'shannon'}->[5]->[0], 65;
    cmp_ok $nums->{'shannon'}->[5]->[1], '>', 0;
    cmp_ok $nums->{'shannon'}->[5]->[1], '<', 1;
    is     $nums->{'shannon'}->[5]->[2], 0;
    cmp_ok $nums->{'shannon'}->[5]->[3], '>', 0;
    cmp_ok $nums->{'shannon'}->[5]->[3], '<', 1;

    is     $nums->{'shannon'}->[6]->[0], 81;
    cmp_ok $nums->{'shannon'}->[6]->[1], '>', 0;
    cmp_ok $nums->{'shannon'}->[6]->[1], '<', 1;
    is     $nums->{'shannon'}->[6]->[2], 0;
    cmp_ok $nums->{'shannon'}->[6]->[3], '>', 0;
    cmp_ok $nums->{'shannon'}->[6]->[3], '<', 1;

    is     $nums->{'shannon'}->[7]->[0], 97;
    is     $nums->{'shannon'}->[7]->[1], '';
    is     $nums->{'shannon'}->[7]->[2], 0;
    cmp_ok $nums->{'shannon'}->[7]->[3], '>', 0;
    cmp_ok $nums->{'shannon'}->[7]->[3], '<', 1;

    is     $nums->{'shannon'}->[8]->[0], 113;
    is     $nums->{'shannon'}->[8]->[1], '';
    is     $nums->{'shannon'}->[8]->[2], 0;
    cmp_ok $nums->{'shannon'}->[8]->[3], '>', 0;
    cmp_ok $nums->{'shannon'}->[8]->[3], '<', 1;

    is     $nums->{'shannon'}->[9]->[0], 121;
    is     $nums->{'shannon'}->[9]->[1], '';
    is     $nums->{'shannon'}->[9]->[2], 0;
    cmp_ok $nums->{'shannon'}->[9]->[3], '>', 0;
    cmp_ok $nums->{'shannon'}->[9]->[3], '<', 1;

    is     $nums->{'shannon'}->[10]->[0], 129;
    is     $nums->{'shannon'}->[10]->[1], '';
    is     $nums->{'shannon'}->[10]->[2], 0;
    is     $nums->{'shannon'}->[10]->[3], '';

    is     $nums->{'shannon'}->[11]->[0], 142;
    is     $nums->{'shannon'}->[11]->[1], '';
    is     $nums->{'shannon'}->[11]->[2], 0;
    is     $nums->{'shannon'}->[11]->[3], '';


    # Rarefaction with logarithmic spacing

    my $rre = qr/(?:(?i)(?:[+-]?)(?:(?=[.]?[0123456789])(?:[0123456789]*)(?:(?:[.])(?:[0123456789]{0,}))?)(?:(?:[E])(?:(?:[+-]?)(?:[0123456789]+))|))/;
    # regular expression to match a real number, taken from Regexp::Common

    ok $accumulator = Bio::Community::Tools::Accumulator->new(
       -metacommunity => $meta1,
       -type          => 'rarefaction',
       -num_ticks     => 7,
       -tick_spacing  => 'logarithmic',
    ), 'Rarefaction curve (logarithmic)';
    ok $nums = $accumulator->get_strings;

    ok   @string = split /\n/, $nums->[0];
    is   $string[0], "# observed\t20100302\t20100304\t20100823";
    is   $string[1], "0\t0\t0\t0";
    is   $string[2], "1\t1\t1\t1";
    like $string[3], qr/^2\t$rre\t1\t$rre/;
    like $string[4], qr/^4\t$rre\t1\t$rre/;
    like $string[5], qr/^11\t$rre\t1\t$rre/;
    like $string[6], qr/^30\t$rre\t1\t$rre/;
    like $string[7], qr/^81\t2\t1\t$rre/;
    like $string[8], qr/^121\t\t1\t$rre/;
    is $string[9], "142\t\t1\t";
}

done_testing();

exit;
