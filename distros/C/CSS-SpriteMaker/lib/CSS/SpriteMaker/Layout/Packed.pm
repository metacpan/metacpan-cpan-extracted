package CSS::SpriteMaker::Layout::Packed;

use strict;
use warnings;

use base 'CSS::SpriteMaker::Layout';

use CSS::SpriteMaker::Layout::Packed::Node;

=head1 NAME

CSS::SpriteMaker::Layout::Packed - Layout items trying to minimize the size of the resulting file.

    my $DirectoryBasedLayout = CSS::SpriteMaker::Layout::Packed->new(
        {
            "1" => {
                width => 128,
                height => 128,
                pathname => '/full/path/to/file1.png',
                parentdir => '/full/path/to',
            },
            ...
        }
    );


All items will be packed throughcontained in the same sub directory are cascaded on the same row of 
the layout.

Input hashref items must contain the following keys
for this layout to produce a result:

- pathname : the full pathname of the file;

- width : the width in pixels of the image;

- height : the height in pixels of the image;

- parentdir: the full pathname of the parent directory the image is contained
  in.


=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

=head2 new

Instantiates the layout:

    my $PackedLayout = CSS::SpriteMaker::Layout::Packed->new(
        $rh_item_info
    );

=cut

sub new {
    my $class = shift;
    my $rh_items_info = shift;

    my $self = bless {}, $class;

    if (!$rh_items_info) {
        die 'no items info hashref was passed in construction to this layout';
    }

    $self->_layout_items($rh_items_info);
    $self->finalize();

    return $self;
}

=head2 _layout_items

see POD of super class CSS::SpriteMaker::Layout::_layout_items for more
information.

=cut

sub _layout_items {
    my $self          = shift;
    my $rh_items_info = shift;

    # sort items by height
    my @items_sorted =
        sort {
            $rh_items_info->{$b}{height}
                <=>
            $rh_items_info->{$a}{height}

            || $a <=> $b
        }
        keys %$rh_items_info;

    my $root = CSS::SpriteMaker::Layout::Packed::Node->new(
        0, 0,
        $rh_items_info->{$items_sorted[0]}{width},
        $rh_items_info->{$items_sorted[0]}{height}
    );

    my $max_w = 0;
    my $max_h = 0;
    my $node;
    for my $image_id (@items_sorted) {
        my $image = $rh_items_info->{$image_id};
        $node = $root->find($root, $image->{width}, $image->{height});
        if ($node) {
            $node = $root->split($node, $image->{width}, $image->{height});
        }
        else {
            $node = $root->grow($image->{width}, $image->{height});
        }

        $self->set_item_coord($image_id, $node->{x}, $node->{y});

        # compute the overall width/height
        $max_w = $image->{width} + $node->{x} if $max_w < $image->{width} + $node->{x};
        $max_h = $image->{height} + $node->{y} if $max_h < $image->{height} + $node->{y};
    }

    # write dimensions in the resulting layout
    $self->{width} = $max_w;
    $self->{height} = $max_h;

    return;
}

1;
