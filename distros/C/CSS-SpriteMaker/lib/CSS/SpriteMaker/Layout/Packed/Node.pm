package CSS::SpriteMaker::Layout::Packed::Node;

use strict;
use warnings;

=head1 NAME

CSS::SpriteMaker::Layout::Packed::Node - A node of the Packed Layout

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 METHODS

=cut

=head2 new
        
Node constructor.

Parameters:

=over 4

=item X coordinate.

=item Y coordinate.

=item Image width.

=item Image height.

=item Flag to determine if the node is used.

=item Down (Node class).

=item Right (Node class).

=back

=cut

sub new {
    my $class = shift;
    my $x = shift // 0;
    my $y = shift // 0;
    my $width = shift // 0;
    my $height = shift // 0;
    my $used = shift // 0;
    my $down = shift;
    my $right = shift;

    return bless {
        x => $x,
        y => $y,
        width => $width,
        height => $height,
        used => $used,
        right => $right,
        down => $down
    }, $class;
}

=head2 find

Find a node to allocate this image size (width, height).

Node to search in.

Parameters:

=over 4

=item Pixels to grow down (width).

=item Pixels to grow down (height).

=back

=cut

sub find {
    my $self = shift;
    my $node = shift;
    my $width = shift;
    my $height = shift;

    if ($node->{used}) {
        return $self->find($node->{right}, $width, $height) 
            || $self->find($node->{down}, $width, $height);
    }
    elsif ($node->{width} >= $width && $node->{height} >= $height) {
        return $node;
    }

    return 0;
}

=head2 grow

Grow the canvas to the most appropriate direction.

Parameters:

=over 4

=item Pixels to grow down (width).

=item Pixels to grow down (height).

=back

=cut

sub grow {
    my $self = shift;
    my $width = shift;
    my $height = shift;

    my $can_grow_d = $width <= $self->{width};
    my $can_grow_r = $height <= $self->{height};

    my $should_grow_r = $can_grow_r && $self->{height} >= ($self->{width} + $width);
    my $should_grow_d = $can_grow_d && $self->{width} >= ($self->{height} + $height);

    return $self->grow_right($width, $height) if $should_grow_r;
    return $self->grow_down($width, $height) if $should_grow_d;
    return $self->grow_right($width, $height) if $can_grow_r;
    return $self->grow_down($width, $height) if $can_grow_d;

    return 0;
}

=head2 clone

Clone this object.

=cut

sub clone {
    my $self = shift;
    my $copy = bless { %$self }, ref $self;
    return $copy;
}

=head2 grow_right

Grow the canvas to the right.

Parameters:

=over 4

=item Pixels to grow down (width).

=item Pixels to grow down (height).

=back

=cut

sub grow_right {
    my $self = shift;
    my $width = shift;
    my $height = shift;

    my $old_self = $self->clone();
    $self->{used} = 1;
    $self->{x} = 0;
    $self->{y} = 0;
    $self->{width} += $width;
    $self->{down} = $old_self;
    $self->{right} = CSS::SpriteMaker::Layout::Packed::Node->new(
        $old_self->{width},
        0,
        $width,
        $self->{height}
    );

    my $node = $self->find($self, $width, $height);
    if ($node) {
        return $self->split($node, $width, $height);
    }
    return 0;
}

=head2 grow_down 

Grow the canvas down.

Parameters:

=over 4

=item Pixels to grow down (width).

=item Pixels to grow down (height).

=back

=cut

sub grow_down {
    my $self = shift; 
    my $width = shift;
    my $height = shift;
    
    my $old_self = $self->clone();
    $self->{used} = 1;
    $self->{x} = 0;
    $self->{y} = 0;
    $self->{height} += $height;
    $self->{right} = $old_self;
    $self->{down} = CSS::SpriteMaker::Layout::Packed::Node->new(
        0,
        $old_self->{height},
        $self->{width},
        $height
    );

    my $node = $self->find($self, $width, $height);
    if ($node) {
        return $self->split($node, $width, $height);
    }

    return 0;
}

=head2 split

Split the node to allocate a new one of this size.

Parameters:

=over 4

=item Node to be splitted.

=item New node width.

=item New node height.

=back

=cut

sub split {
    my $self = shift;
    my $node = shift;
    my $width = shift;
    my $height = shift;

    $node->{used} = 1;
    $node->{down} = CSS::SpriteMaker::Layout::Packed::Node->new(
        $node->{x},
        $node->{y} + $height,
        $node->{width},
        $node->{height} - $height
    );
    $node->{right} = CSS::SpriteMaker::Layout::Packed::Node->new(
        $node->{x} + $width,
        $node->{y},
        $node->{width} - $width,
        $height
    );

    return $node;
}

1;
