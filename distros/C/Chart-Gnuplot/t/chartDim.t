#!/usr/bin/perl -w
use strict;
use Test::More (tests => 4);

BEGIN {use Chart::Gnuplot;}

my $temp = "temp.ps";

# Test setting the orientation
{
    my $c = Chart::Gnuplot->new(
        output => $temp,
        orient => 'portrait',
    );

    $c->_setChart();
    ok($c->{terminal} =~ /portrait$/);
}


# Test setting image size
{
    my $c = Chart::Gnuplot->new(
        output    => $temp,
        imagesize => "0.9, 1.1",
    );

    $c->_setChart();
    ok($c->{terminal} =~ /size 9,7\.7$/);
}


# Test setting image size of portrait image
{
    my $c = Chart::Gnuplot->new(
        output    => $temp,
        orient    => 'portrait',
        imagesize => "0.9, 1.1",
    );

    $c->_setChart();
    ok($c->{terminal} =~ /portrait size 6\.3,11$/);
}


# Test setting image size with specified unit
{
    my $c = Chart::Gnuplot->new(
        output    => $temp,
        imagesize => "18 cm, 4 inches",
    );

    $c->_setChart();
    ok($c->{terminal} =~ /size 18 cm,4 inches$/);
}
