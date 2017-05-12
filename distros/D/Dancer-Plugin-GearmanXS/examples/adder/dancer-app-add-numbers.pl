#!/usr/bin/env perl
use strict;
use warnings;
use Dancer;
use FindBin;
use lib "$FindBin::Bin/../../lib";

use Dancer::Plugin::GearmanXS;

get qr,^/(?<numbers>.*)$, => sub {
    my @numbers = split( '/', captures->{numbers} );
    return "Give me numbers: http://localhost:3000/1/2/3\n" if !@numbers;
    my $sum = gearman_do( 'add', \@numbers );
    return "Error: no numbers given\n" if !$sum;
    "Sum is $sum\n";
};

dance;
