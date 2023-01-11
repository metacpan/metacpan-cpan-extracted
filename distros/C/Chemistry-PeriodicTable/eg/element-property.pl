#!/usr/bin/env perl
use strict;
use warnings;

# Plot the value of a property for each element

use Chart::Lines ();
use lib map { "$ENV{HOME}/sandbox/$_/lib" } qw(Chemistry-PeriodicTable);
use Chemistry::PeriodicTable ();

my $property = shift || 'weight';

my $pt = Chemistry::PeriodicTable->new;

my $width  = shift || 800;
my $height = shift || 400;

my $chart = Chart::Lines->new($width, $height);

$chart->set(
    legend       => 'none',
    title        => "$property per element",
    x_label      => 'Element',
    y_label      => 'Value',
    include_zero => 'true',
    precision    => 2,
    skip_x_ticks => 4,
    brush_size   => 2,
    pt_size      => 4,
    y_grid_lines => 'true',
);

my @data;
for my $symbol (sort { $pt->symbols->{$a}[0] <=> $pt->symbols->{$b}[0] } keys $pt->symbols->%*) {
    push @data, $pt->value($symbol, $property);
}

$chart->add_dataset(1 .. @data);
$chart->add_dataset(@data);

$chart->png("$property-per-element.png");
