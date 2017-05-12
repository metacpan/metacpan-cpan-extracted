[![Build Status](https://travis-ci.org/wang-q/AlignDB-Window.svg?branch=master)](https://travis-ci.org/wang-q/AlignDB-Window) [![Coverage Status](http://codecov.io/github/wang-q/AlignDB-Window/coverage.svg?branch=master)](https://codecov.io/github/wang-q/AlignDB-Window?branch=master) [![MetaCPAN Release](https://badge.fury.io/pl/AlignDB-Window.svg)](https://metacpan.org/release/AlignDB-Window)
# NAME

AlignDB::Window - Split integer spans into a series of windows

# DESCRIPTION

AlignDB::Window provides methods to split integer spans, including interval, inside area and
outside area, into a series of windows.

# ATTRIBUTES

`sw_size`          - sliding windows' size, default is 100

`min_interval`     - mininal indel interval length, default is 11

`max_out_distance` - maximal outside distance, default is 10

`max_in_distance`  - maximal inside distance, default is 5

# METHODS

## common parameters

`$comparable_set`      - AlignDB::IntSpan object

`$interval_start`      - start point of the interval

`$interval_end`        - end point in the interval

`$internal_start`      - start position in the internal region

`$internal_end`        - end position in the internal region

`$sw_size`             - size of windows

`$min_interval`        - minimal size of intervals

`$maximal_distance`    - maximal distance

`$strand`              - '+' or '-'

## interval\_window

    my @interval_windows = $self->interval_window(
        $comparable_set, $interval_start, $interval_end,
        $sw_size, $min_interval,
    );

Split an interval to windows.

Length of windows are variable, but all positions of the interval are counted.

## outside\_window

    my @outside_windows = $self->outside_window(
        $comparable_set, $internal_start, $internal_end,
        $sw_size, $maximal_distance,
    );

Draw outside windows from a internal region.

All windows are 100 bp length. Start from 1 and end to $maximal\_distance.

## outside\_window\_2

    my @outside_windows = $self->outside_window_2(
        $comparable_set, $internal_start, $internal_end,
        $sw_size, $maximal_distance,
    );

Draw outside windows from a internal region.

The first window is 50 bp and all others are 100 bp length.
Start from 0 and end to $maximal\_distance.

## inside\_window

    my @inside_windows = $self->inside_window(
        $comparable_set, $interval_start, $interval_end,
        $sw_size, $maximal_distance,
    );

Draw inside windows from a internal region.

All windows are 100 bp length. Start counting from the edges.

## inside\_window\_2

    my @inside_windows = $self->inside_window_2(
        $comparable_set, $interval_start, $interval_end,
        $sw_size, $maximal_distance,
    );

Draw inside windows from a internal region.

All windows are 100 bp length. Start counting from the center.

## center\_window

    my @center_windows = $self->center_window(
        $comparable_set, $internal_start, $internal_end,
        $sw_size, $maximal_distance,
    );

Draw windows for a certain region.

Center is 0, and the first window is 50 bp and all others are 100 bp length.
Start from 0 and end to $maximal\_distance.

## center\_intact\_window

    my @center_intact_windows = $self->center_intact_window(
        $comparable_set, $internal_start, $internal_end,
        $sw_size, $maximal_distance,
    );

Draw windows for a certain region.

Center is 0, and the first window is 50 bp and all others are 100 bp length.
Start from 0 and end to $maximal\_distance.

## strand\_window

    my @windows = $self->strand_window(
        $comparable_set, $interval_start, $interval_end,
        $sw_size, $strand,
    );

Draw windows for a certain region

# AUTHOR

Qiang Wang &lt;wang-q@outlook.com>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2008 by Qiang Wang.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
