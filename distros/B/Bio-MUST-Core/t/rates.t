#!/usr/bin/env perl

use Test::Most;

use autodie;
use feature qw(say);

use List::AllUtils qw(sum);
use Path::Class qw(file);

use Bio::MUST::Core;
use Bio::MUST::Core::Utils qw(:tests);

my $class = 'Bio::MUST::Core::SeqMask::Rates';

my @exp_data = (
    {
        basename => 'primate',
        len => 898,
        bin_n => 10,
        args => { descending => 1 },
        bins => [ 373, 0, 3, 0, 0, 68, 73, 37, 152, 192 ],
    },
    {
        basename => 'primate',
        len => 898,
        bin_n => 10,
        args => { cumulative => 1, descending => 1 },
        bins => [ 373, 373, 376, 376, 376, 444, 517, 554, 706, 898 ],
    },
    {
        basename => 'primate',
        len => 898,
        bin_n => 5,
        args => { percentile => 1, descending => 1 },
        bins => [ 180, 180, 180, 180, 178 ],
    },
    {
        basename => 'primate',
        len => 898,
        bin_n => 5,
        args => { cumulative => 1, percentile => 1, descending => 1 },
        bins => [ 180, 360, 540, 720, 898 ],
    },
    {
        basename => 'thermus',
        len => 1273,
        bin_n => 10,
        args => { descending => 1 },
        bins => [ 833, 0, 0, 0, 0, 116, 87, 72, 96, 69 ],
    },
    {
        basename => 'thermus',
        len => 1273,
        bin_n => 10,
        args => { cumulative => 1, descending => 1 },
        bins => [ 833, 833, 833, 833, 833, 949, 1036, 1108, 1204, 1273 ],
    },
    {
        basename => 'thermus',
        len => 1273,
        bin_n => 6,
        args => { percentile => 1, descending => 1 },
        bins => [ 213, 213, 213, 213, 213, 208 ],
    },
    {
        basename => 'thermus',
        len => 1273,
        bin_n => 6,
        args => { percentile => 1, cumulative => 1, descending => 1 },
        bins => [ 213, 426, 639, 852, 1065, 1273 ],
    },
);

for my $data (@exp_data) {
    my ($basename, $exp_len, $bin_n, $args, $exp_bins)
        = @{$data}{ qw(basename len bin_n args bins) };

    my $infile = file('test', "$basename.rates");
    my $rates = $class->load($infile);
    isa_ok $rates, $class, $infile;
    cmp_ok $rates->mask_len, '==', $exp_len,
        'read expected number of site rates';
    my @masks = $rates->bin_rates_masks($bin_n, $args);

    BIN:
    for (my $i = 0; $i < @masks; $i++) {
        my $count = $masks[$i]->count_sites;
        cmp_ok $count, '==', $exp_bins->[$i],
            "got expected number of sites for bin $i: $count";
    }
}

{
    my $infile = file('test', 'supermatrix-CATG-A-sample.rate');
    my $rates = $class->load($infile);
    isa_ok $rates, $class, $infile;
    cmp_ok $rates->mask_len, '==', 17167,
        'read expected number of site rates';

    my $bin_n = 10;
    my $args = { percentile => 1 };
    my @masks = $rates->bin_rates_masks($bin_n, $args);

    my $alifile = file('test', 'supermatrix.ali');
    my $ali = Bio::MUST::Core::Ali->load($alifile);
    $ali->apply_mask( Bio::MUST::Core::SeqMask->variable_mask($ali) );

    for my $i (0..$#masks) {
        cmp_store(
            obj    => $masks[$i]->filtered_ali($ali),
            method => 'store',
            file   => "supermatrix-bin$i.ali",
            test   => 'wrote expected filtered Ali based on bin $i',
        );
    }
}

{
    my $s_infile = file('test', 'test-self.meansiterates');
    my $s_rates = $class->load($s_infile);
    my $o_infile = file('test', 'test-othr.meansiterates');
    my $o_rates = $class->load($o_infile);

    my $delta_rates = $s_rates->delta_rates($o_rates);
    cmp_store(
        obj    => $delta_rates,
        method => 'store',
        file   => 'test-delta.rates',
        test   => 'wrote expected delta-rates file',
    );
}

{
    my $infile = file('test', 'rg-supermatrix-IQTREE.rate');
    my $rates = $class->load($infile);
    isa_ok $rates, $class, $infile;
    cmp_ok $rates->mask_len, '==', 1000,
        'read expected number of site rates for IQ-TREE .rate file';

    my $epsilon = 1e-12;

    cmp_float $rates->min_rate, 0.30935, $epsilon,
        'got expected min rate';
    cmp_float $rates->max_rate, 1.91612, $epsilon,
        'got expected max rate';
    cmp_float sum($rates->all_states) / $rates->mask_len, 0.77959709, $epsilon,
        'got expected mean rate';
}

done_testing;
