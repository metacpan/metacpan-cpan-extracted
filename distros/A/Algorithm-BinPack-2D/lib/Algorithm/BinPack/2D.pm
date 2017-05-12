# vim: set expandtab ts=4 sw=4 nowrap ft=perl ff=unix :
package Algorithm::BinPack::2D;

use strict;
use warnings;
use Carp;

our $VERSION = 0.03;

=head1 NAME

Algorithm::BinPack::2D - efficiently pack items into rectangles

=head1 SYNOPSIS

C<Algorithm::BinPack::2D> efficiently packs items into bins.
The bins are given a maximum width and height,
and items are packed in with as little empty space as possible.
An example use would be backing up small images to concatenated images,
while minimizing the number of images required.

    my $bp = Algorithm::BinPack::2D->new(binwidth => 512, binheight => 512);

    $bp->add_item(label => "one.png",   width =>  30, height =>  10);
    $bp->add_item(label => "two.png",   width => 200, height =>  40);
    $bp->add_item(label => "three.png", width =>  30, height => 300);
    $bp->add_item(label => "four.png",  width => 400, height => 100);

    for ($bp->pack_bins) {
        print "Bin width: ", $_->{width}, " x ", $_->{height}, "\n";
        print "     Item: ", $_->{label}, "\n" for @{ $_->{items} };
    }
=cut

=head1 METHODS

=over 8

=item new

Creates a new C<Algorithm::BinPack::2D> object.
The maximum bin width and height is specified as a named argument 'binwidth' and 'binheight',
and is required.

    my $bp = Algorithm::BinPack::2D->new(binwidth => 512, binheight => 512);

=cut

sub new {
    my $name = shift;
    my $self = {@_};

    bless $self, $name;
}

=item add_item

Adds an item to be packed into a bin.
Required named arguments are 'label', 'width' and 'height',
but any others can be specified, and will be saved.

    $bp->add_item(label => 'one',  width => 1, height => 1);

=cut

sub add_item {
    my $self = shift;
    my $item = {@_};

    unless ($item->{label}
        && $item->{width}
        && $item->{height}
        && $item->{width} > 0
        && $item->{height} > 0) {
        croak 'Item must have label, width and height.';
    }

    if (   $self->{binwidth} < $item->{width}
        || $self->{binheight} < $item->{height}) {
        croak
          "Item size is too big. Max size is $self->{binwidth}x$self->{binheight}.";
    }

    push @{ $self->{items} }, $item;
}

=item pack_bins

Packs the items into bins.
This method tries to leave as little empty space in each bin as possible.
It returns a list of hashrefs with the key
'width' containing the total bin width,
'height' containing the total bin height,
and 'items' containing an arrayref holding the items in the bin.
Each item is in turn a hashref containing the keys 'label', 'x', 'y', 'width' and 'height'.

    for my $bin ($bp->pack_bins) {
        print "Bin width: ", $bin->{width}, " x ", $bin->{height}, "\n";

        for my $item (@{ $bin->{items} }) {
            printf "  %-6s %-20s\n", $_, $item->{$_} for keys %{ $item };
            print  "  ---\n";
        }
    }

=cut

sub pack_bins {
    my $self       = shift;
    my $bin_width  = $self->{binwidth};
    my $bin_height = $self->{binheight};

    my @bins;
    push @bins, make_new_bin($bin_width, $bin_height);

    for my $item (sort_items($self->{items})) {
        my ($width, $height, $label) = @{$item}{qw(width height label)};
        my $rect;
        for my $bin (@bins) {
            $rect = pack_in_a_bin($bin, $width, $height, $label);
            last if $rect;
        }
        unless ($rect) {
            my $new_bin = make_new_bin($bin_width, $bin_height);
            push @bins, $new_bin;
            $rect = pack_in_a_bin($new_bin, $width, $height, $label);
        }
    }

    # filter filled nodes
    map {
        my $bin   = $_;
        my $items = [];
        my ($max_width, $max_height) = filter_filled_node($bin, $items, 0, 0);
        +{
            width  => $max_width,
            height => $max_height,
            items  => $items,
          }
    } @bins;
} ## end sub pack_bins

sub filter_filled_node {
    my ($bin, $filtered_nodes, $max_width, $max_height) = @_;

    ($max_width, $max_height) =
      filter_filled_node($bin->{left}, $filtered_nodes, $max_width, $max_height)
      if $bin->{left};
    ($max_width, $max_height) = filter_filled_node(
        $bin->{right}, $filtered_nodes, $max_width,
        $max_height
    ) if $bin->{right};

    if ($bin->{filled}) {
        push @$filtered_nodes,
          +{
            x      => $bin->{x},
            y      => $bin->{y},
            label  => $bin->{label},
            width  => $bin->{width},
            height => $bin->{height},
          };
        my $max_x = $bin->{x} + $bin->{width};
        my $max_y = $bin->{y} + $bin->{height};
        $max_width  = $max_x if $max_width < $max_x;
        $max_height = $max_y if $max_height < $max_y;
    }
    ($max_width, $max_height);
}

sub make_new_bin {
    my ($bin_width, $bin_height) = @_;

    return +{
        x      => 0,
        y      => 0,
        filled => 0,
        width  => $bin_width,
        height => $bin_height,
    };
}

sub pack_in_a_bin {
    my ($bin, $width, $height, $label) = @_;

    if ($bin->{left}) {
        return pack_in_a_bin($bin->{left}, $width, $height, $label)
          || pack_in_a_bin($bin->{right}, $width, $height, $label);
    }

    if (   $bin->{filled}
        || $bin->{width} < $width
        || $bin->{height} < $height) {
        return;
    }

    if ($bin->{width} == $width && $bin->{height} == $height) {
        $bin->{filled} = 1;
        $bin->{label}  = $label;
        return $bin;
    }

    my $width_diff  = $bin->{width} - $width;
    my $height_diff = $bin->{height} - $height;

    if ($width_diff > $height_diff) {
        $bin->{left} = +{
            x      => $bin->{x},
            y      => $bin->{y},
            filled => 0,
            width  => $width,
            height => $bin->{height},
        };
        $bin->{right} = +{
            x      => $bin->{x} + $width,
            y      => $bin->{y},
            filled => 0,
            width  => $width_diff,
            height => $bin->{height},
        };
    } else {
        $bin->{left} = +{
            x      => $bin->{x},
            y      => $bin->{y},
            filled => 0,
            width  => $bin->{width},
            height => $height,
        };
        $bin->{right} = +{
            x      => $bin->{x},
            y      => $bin->{y} + $height,
            filled => 0,
            width  => $bin->{width},
            height => $height_diff,
        };
    }

    return pack_in_a_bin($bin->{left}, $width, $height, $label);
} ## end sub pack_in_a_bin

sub sort_items {
    my $items = shift;

    sort {
        # Sorting by max(width, height) is the best heuristic.
        my $abigger = $a->{width} > $a->{height} ? $a->{width} : $a->{height};
        my $bbigger = $b->{width} > $b->{height} ? $b->{width} : $b->{height};

        my $asmaller = $a->{width} <= $a->{height} ? $a->{width} : $a->{height};
        my $bsmaller = $b->{width} <= $b->{height} ? $b->{width} : $b->{height};

             $bbigger <=> $abigger
          || $bsmaller <=> $asmaller
          || $b->{width} <=> $a->{width}
          || $a->{label} cmp $b->{label}
    } @{$items};
}

1;

=back

=head1 SEE ALSO

C<Algorithm::BinPack>

=head1 AUTHOR

Tasuku SUENAGA a.k.a. gunyarakun E<lt>tasuku-s-cpan ATAT titech.acE<gt>

=head1 LICENSE

Copyright (C) Tasuku SUENAGA a.k.a. gunyarakun

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
=cut
