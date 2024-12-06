#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

use Daje::Tools::Datasections;

sub load_all_templates {
    my $test = Daje::Tools::Datasections->new();
    return 1;
}

ok(load_all_templates()==1);

done_testing();

1;