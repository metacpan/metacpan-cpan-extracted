#!/usr/bin/perl

use warnings;
use strict;

use GD;
use AI::FANN qw(:all);

my $num = 500;
my $size = 16;

$| = 1;

sub draw_o {
    my ($im, $color) = @_;
    my $r = int (0.2 + rand(0.25 * $size));
    my $x0 = $r + int rand($size - 2 * $r);
    my $y0 = $r + int rand($size - 2 * $r);
    $im->arc($x0, $y0, $r, $r, 0, 360, $color);
    return 2*$r/$size
}

sub draw_x {
    my ($im, $color) = @_;
    my $r = int (0.2 + rand(0.25 * $size));
    my $x0 = $r + int rand($size - 2 * $r);
    my $y0 = $r + int rand($size - 2 * $r);
    $im->line($x0-$r, $y0-$r, $x0+$r, $y0+$r, $color);
    $im->line($x0-$r, $y0+$r, $x0+$r, $y0-$r, $color);
    return 2*$r/$size
}

sub image_to_input {
    my ($im, $type) = @_;
    my @data;
    for my $x (0..$size-1) {
        for my $y (0..$size-1) {
            push @data, $im->getPixel($x, $y);
        }
    }
    return \@data;
}

sub make_train {
    my $train = AI::FANN::TrainData->new_empty($num, $size * $size, 2);
    for (0..$num - 1) {
        print ".";
        my $im = GD::Image->new($size, $size);
        my $white = $im->colorAllocate(255,255,255);
        my $black = $im->colorAllocate(0,0,0);
        my $type = (rand > .5);
        my $r = $type ? draw_x($im, $black) : draw_o($im, $black);
        $train->data($_, image_to_input($im), [$type, $r]);
    }
    print "\n";
    my $ann = AI::FANN->new_standard(@_);
    for (1..40) {
        $ann->train_on_data($train, 100, 1, 0.0001);
        # $ann->print_connections;
        $ann->print_parameters;
        $ann->save("ox.ann");
    }
}

sub make_test {
    my $rep = shift;
    my $ann = AI::FANN->new_from_file("ox.ann");
    print "ann read\n";
    for (0..$rep - 1) {
        my $im = GD::Image->new($size, $size);
        my $white = $im->colorAllocate(255,255,255);
        my $black = $im->colorAllocate(0,0,0);
        my $type = (rand > .5);
        my $r = $type ? draw_x($im, $black) : draw_o($im, $black);
        my $out = $ann->run(image_to_input($im));
        printf ("type: %f, r: %4.2f out type: %f, r: %4.2f\n", $type, $r, $out->[0], $out->[1]);
    }
}

if ($ARGV[0] eq 'train') {
    make_train($size * $size, 4 * $size * $size, 240, 200, 60, 20, 2);
}
elsif ($ARGV[0] eq 'test') {
    make_test($ARGV[1] || 10);
}
else {
    die "wrong action"
}
