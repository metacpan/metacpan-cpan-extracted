#! perl

use strict;
use warnings;

use Test::More;
use Business::Colissimo;

my @tests = ({country => 'FR',
              mode => 'expert_f',
              organisation => 'EPG'},
             {country => 'BR',
              mode => 'expert_i',
              organisation => 'KPG'},
             {country => 'FI',
              mode => 'expert_i',
              organisation => 'EPG'},
              {country => 'SI',
              mode => 'expert_i',
              organisation => ''},
    );

my ($colissimo, $ret, $mode);

plan tests => scalar @tests;

for my $ref (@tests) {
    $colissimo = Business::Colissimo->new(mode => $ref->{mode},
                                          country_code => $ref->{country});

    $ret = $colissimo->organisation;

    ok ($ret eq $ref->{organisation}, "Testing organisation for country $ref->{country}")
        || diag "Wrong organisation for country $ref->{country}: $ret.";
}

