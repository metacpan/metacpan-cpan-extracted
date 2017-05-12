#!/usr/bin/env perl

use strict;
use warnings;

use Chart::Lines;

my $w = 600;
my $h = 300;

my $obj = Chart::Lines->new;
$obj = Chart::Lines->new($w, $h);

$obj->set('title' => 'Graphics Test');
$obj->set('x_label' => 'Hours');

sub rand_numbers {

    my @set;

    for (0 .. 23) {
        push @set, rand 100;
    }

    return @set;
}

my @hours = 0 .. 23;

my @set1 = rand_numbers;
my @set2 = rand_numbers;
my @set3 = rand_numbers;

$obj->add_dataset(@hours);
$obj->add_dataset(@set1);
$obj->add_dataset(@set2);
$obj->add_dataset(@set3);
$obj->cgi_png;


