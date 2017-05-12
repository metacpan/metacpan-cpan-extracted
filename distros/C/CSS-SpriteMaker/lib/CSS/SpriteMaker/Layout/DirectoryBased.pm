package CSS::SpriteMaker::Layout::DirectoryBased;

use strict;
use warnings;

use base 'CSS::SpriteMaker::Layout';

=head1 NAME

CSS::SpriteMaker::Layout::DirectoryBased

    my $DirectoryBasedLayout = CSS::SpriteMaker::Layout::DirectoryBased->new(
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

Layout items based on the directory they are contained in and their filename.

All items contained in the same sub directory are cascaded on the same row of 
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

    my $DirectoryBasedLayout = CSS::SpriteMaker::Layout::DirectoryBased->new(
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



=cut

sub _layout_items {
    my $self          = shift;
    my $rh_items_info = shift;

    # 1. sort items by directory, then filename
    my @items_id_sorted = 
    sort {
        $rh_items_info->{$a}{pathname}
            cmp
        $rh_items_info->{$b}{pathname}

        || $a <=> $b
    }
    keys %$rh_items_info;
    
    # 2. put items from the same directory in the same row
    my $x = 0;
    my $y = 0;
    my $total_height = 0;
    my $total_width = 0;
    my $row_height = 0;

    my $parentdir_prev;
    for my $id (@items_id_sorted) {
        my $w = $rh_items_info->{$id}{width};
        my $h = $rh_items_info->{$id}{height};
        my $parentdir = $rh_items_info->{$id}{parentdir};

        if (defined $parentdir_prev && $parentdir ne $parentdir_prev) {
            # next row!
            $y += $row_height;
            $x = 0;
            $row_height = 0;
        }

        # chain on this row...
        $self->set_item_coord($id, $x, $y);

        $x += $w;
        $row_height = $h if $h > $row_height;
        $total_width = $x if $x > $total_width;
        $total_height = $y + $row_height if $y + $row_height > $total_height;

        $parentdir_prev = $parentdir;
    }

    $self->{width} = $total_width;
    $self->{height} = $total_height;

    return;
}

1;
