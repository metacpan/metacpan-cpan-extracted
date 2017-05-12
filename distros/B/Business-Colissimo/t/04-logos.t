#! perl

use strict;
use warnings;

use Test::More;
use Business::Colissimo;

my ($colissimo, $logo, @modes);

# test logos
@modes = qw/access_f expert_f expert_om expert_i expert_i_kpg/;

plan tests => scalar @modes;

for my $m (@modes) {
    $colissimo = Business::Colissimo->new(mode => $m);

    $logo = $colissimo->logo;
    
    ok($logo =~ /^\S+\.bmp$/, "Testing logo for mode $m")
        || diag "Wrong logo name for mode $m: $logo.";
}

