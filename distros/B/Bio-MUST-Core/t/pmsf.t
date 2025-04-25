#!/usr/bin/env perl

use Test::Most;

use autodie;
use feature qw(say);

# use Const::Fast;
use Path::Class qw(file);
# use Scalar::Util qw(looks_like_number);

use Bio::MUST::Core;
use Bio::MUST::Core::Utils qw(:tests);

my $class = 'Bio::MUST::Core::SeqMask::Pmsf';

# const my $PREC => 10;

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
#       filter => \&round_filter,
    );
}

# Note: unnecessary due to fix in .pm itself
# sub round_filter {
#     my $line = shift;
#     return looks_like_number $line ? sprintf "%.${PREC}f\n", $line : $line;
# }


done_testing;
