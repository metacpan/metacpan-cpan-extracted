package Chart::Sequence::Layout;

$VERSION = 0.000_1;

=head1 NAME

Chart::Sequence::Layout - Lay out a sequence so it can be rendered

=head1 SYNOPSIS

    use Chart::Sequence::Layout;

    my $layout = Chart::Sequence::Layout->new( ... );

    $layout->layout( $sequence );

=head1 DESCRIPTION

Takes a sequence and lays it out.  Leaves coordinates in the source sequence.

=for test_script t/Chart-Sequence-Renderer-Imager.t

=cut

use POSIX qw( floor );
use Chart::Sequence::Object ();
@ISA = qw( Chart::Sequence::Object );

use strict;

## For whole diagram
use constant diagram_margins  => 10;
use constant diagram_left_margin   => diagram_margins;
use constant diagram_right_margin  => diagram_margins;
use constant diagram_top_margin    => diagram_margins;
use constant diagram_bottom_margin => diagram_margins;

## For box labels
use constant box_margins => 10;
use constant box_left_margin   => box_margins;
use constant box_right_margin  => box_margins;
use constant box_top_margin    => box_margins;
use constant box_bottom_margin => box_margins;

use constant box_spacing => 10;

use constant first_message_spacing => 20;
use constant last_message_spacing => 10;

use constant message_top_margin         => 2;
use constant message_bottom_margin      => 2;
use constant message_left_margin        => 2;
use constant message_right_margin       => 2;

=head2 METHODS

=over

=cut

=item lay_out

    $layout->lay_out( $sequence, $renderer, $options );

Adds a set of coordinates to each object in $sequence.

Options:

    DiagonalArrows => 1,     # Make arrows angle in direction of time.

=cut

sub lay_out {
    my $self = shift;
    my ( $sequence, $renderer, $options ) = @_;
    $options ||= {};
#    $options->{DiagonalArrows} = 1;

    my @messages = sort {
        ( $a->send_time || 0 ) <=> ( $b->send_time || 0 )
                               ||
        ( $a->number    || 0 ) <=> ( $b->number    || 0 )
    } $sequence->messages;

    my @nodes    = $sequence->nodes;

    ## Gather the necessary metrics
    my $nodes_h = 0;
    for ( @nodes ) {
        my $l = {};
        $_->_layout_info( $l );

        my $label = $_->name;
        my $lm = $l->{label_metrics} = $renderer->string_metrics(
            %$options,
            string => $label,
        );

        $l->{label}     = $label;
        $l->{font}      = $lm->{font};
        $l->{fontcolor} = $lm->{color};
        $l->{w} = $lm->{w} + box_left_margin + box_right_margin;
        $l->{h} = $lm->{h} + box_top_margin + box_bottom_margin;
        $nodes_h = $l->{h} if $l->{h} > $nodes_h;
    }

    my $messages_w = 0;
    for ( @messages ) {
        my $l = {};
        $_->_layout_info( $l ); 

        my $label = $_->name;
        my $lm = $l->{label_metrics} = $renderer->string_metrics(
            color  => $_->color,
            %$options,
            string => $label,
        );

        $l->{label}     = $label;
        $l->{font}      = $lm->{font};
        $l->{fontcolor} = $lm->{color};
        $lm->{h} += message_top_margin + message_bottom_margin;
        $lm->{w} += message_left_margin + message_right_margin;
        $messages_w = $lm->{w} if $lm->{w} > $messages_w;
    }

    # Lay out the image
    my $w = 0;
    my $h = 0;
    { # nodes.
        my $x = diagram_left_margin + $messages_w;
        my $y = diagram_top_margin;

        for ( @nodes ) {
            my $l = $_->_layout_info;

            my $lm = $l->{label_metrics};

            $l->{x} = $x;
            $l->{y} = $y;
            $l->{lx} = $x + box_left_margin + $lm->{x_offs};
            $l->{ly} = $y + box_top_margin  + $lm->{y_offs};
            $l->{cx} = $l->{x} + floor( $l->{w} / 2 );
            $x += $l->{w} + box_spacing;
        }
        $w = $x if $x > $w;
        $h = $y if $y > $h;
    }

    { # messages & arrows
        my $greybar_index = 0;
        my $x = diagram_left_margin;
        my $y = diagram_top_margin + $nodes_h + first_message_spacing;

        for ( @messages ) {
            my $l = $_->_layout_info;
            my $f = $sequence->node_named( $_->from )->_layout_info;
            my $t = $sequence->node_named( $_->to   )->_layout_info;
            my $lm = $l->{label_metrics};

            $l->{gb_index} = $greybar_index;
            $greybar_index = $greybar_index ? 0 : 1;
            $l->{gby1} = $y;
            $l->{gby2} = $l->{gby1} + $lm->{h};

            $l->{lx}  = $x + message_left_margin;
            $l->{ly}  = $y + message_top_margin;

            $l->{x1} = $f->{cx};
            $l->{x2} = $t->{cx};

            if ( $options->{DiagonalArrows} ) {
                $l->{y1} = $y + message_top_margin;
                $l->{y2} = $y + $lm->{h} - message_bottom_margin;
            }
            else {
                $l->{y1} = $l->{y2} =
                    $y + floor( 0.5 + message_top_margin + $lm->{b_offs} / 2 );
            }

            $y += $lm->{h};
        }
        $y += last_message_spacing;
        
        $h = $y if $y > $h;
    }

    for ( map $_->_layout_info, $sequence->nodes ) {
        $_->{end_y} = $h;
    }

    $sequence->_layout_info(
        {
            w => $w + diagram_right_margin,
            h => $h + diagram_bottom_margin,
        }
    );

    for ( map $_->_layout_info, $sequence->messages ) {
        $_->{gbx1} = diagram_left_margin;
        $_->{gbx2} = $w - diagram_right_margin;
    }
}

=back

=head1 LIMITATIONS

=head1 COPYRIGHT

    Copyright 2002, R. Barrie Slaymaker, Jr., All Rights Reserved

=head1 LICENSE

You may use this module under the terms of the BSD, Artistic, oir GPL licenses,
any version.

=head1 AUTHOR

Barrie Slaymaker <barries@slaysys.com>

=cut

1;
