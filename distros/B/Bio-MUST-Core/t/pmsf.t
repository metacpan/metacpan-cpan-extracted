#!/usr/bin/env perl

use Test::Most;

use autodie;
use feature qw(say);

use Path::Class qw(file);

use Bio::MUST::Core;
use Bio::MUST::Core::Utils qw(:tests);

my $class = 'Bio::MUST::Core::SeqMask::Pmsf';

{
    my $s_infile = file('test', 'test-pmsf-archaea.sitefreq');
    my $s_rates = $class->load($s_infile);
    my $o_infile = file('test', 'test-pmsf-euka.sitefreq');
    my $o_rates = $class->load($o_infile);

    my $delta_rates = $s_rates->chi_square_stats($o_rates);
    cmp_store(
        obj    => $delta_rates,
        method => 'store',
        file   => 'test-pmsf-chi-square.stats',
        test   => 'wrote expected chi-square file',
    );
}

done_testing;
