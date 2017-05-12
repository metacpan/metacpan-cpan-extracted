package Chart::Sequence::Renderer::Imager;

$VERSION = 0.000_1;

=head1 NAME

Chart::Sequence::Renderer::Imager - Render a sequence diagram with Imager.pm

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

use POSIX qw( floor ceil );
use Chart::Sequence::Object ();
use Imager ();

@ISA = qw( Chart::Sequence::Object );

use strict;

use constant arrow_length => 6;

sub new {
    my $self = shift->SUPER::new( @_ );
}

=head2 METHODS

=over

=item lay_out

    $renderer->lay_out( $sequence );
    $renderer->lay_out( $sequence, {
        Layout => $layout,
    } );

Uses Chart::Sequence::Layout if no $layout module reference is provided.

Prepares a sequence for rendering with this renderer.

=cut

sub lay_out {
    my $self = shift;
    my ( $sequence, $options ) = @_;
    $options ||= {};

    my $layout = $options->{layout} || do {
        require Chart::Sequence::Layout;
        Chart::Sequence::Layout->new;
    };

    $layout->lay_out( $sequence, $self, $options );
}

=item render_to_file

Given a layed out sequence, generate an image file.

    $renderer->render_to_file( $s, "foo.png" );

Lays out the image if it's not layed out.

=cut

sub _render {
    my $self = shift;
    my ( $sequence, $options ) = @_;

    $self->lay_out( $sequence, $options )
        unless $sequence->_layout_info;

    my $l = $sequence->_layout_info;
    my $i = Imager->new(
        xsize => $l->{w},
        ysize => $l->{h},

    );

    $i->box( color => "#ffffff", filled => 1 );

    ## greybar the background
    for ( map $_->_layout_info, $sequence->messages ) {
        next if $_->{gb_index};

        $i->box(
            xmin   => $_->{gbx1},
            ymin   => $_->{gby1},
            xmax   => $_->{gbx2} - 1,
            ymax   => $_->{gby2} - 1,
            filled => 1,
            color  => "#E0FFE0",
        );
    }

    ## Node boxes along the top
    my $node_outline_color = Imager::Color->new( "#808080" );
    for ( map $_->_layout_info, $sequence->nodes ) {
        my $ly = $_->{y} + $_->{h} - 1;
        $i->box(
            color  => $node_outline_color,
            filled => 0,
            xmin   => $_->{x},
            xmax   => $_->{x} + $_->{w} - 1,
            ymin   => $_->{y},
            ymax   => $ly,
        );

        $i->string(
            text  => $_->{label},
            font  => $_->{font},
            x     => $_->{lx},
            y     => $_->{ly} + $_->{label_metrics}->{b_offs},
            color => $_->{fontcolor},
            align => 1,
            aa    => 1,
        );

        $i->line(
            x1 => $_->{cx},
            y1 => $ly,
            x2 => $_->{cx},
            y2 => $_->{end_y},
            aa => 0,
            color => "#808080",
        );
    }

    for ( map $_->_layout_info, $sequence->messages ) {
        ## Message lines.
        $i->line(
            x1    => $_->{x1},
            y1    => $_->{y1},
            x2    => $_->{x2},
            y2    => $_->{y2},
            aa    => 1,
            color => $_->{fontcolor},
        );

        my @arrowhead_points = do {
            my $angle = atan2
                $_->{x1} - $_->{x2},
                $_->{y1} - $_->{y2};
            my $cw_angle  = $angle + 0.5;
            my $ccw_angle = $angle - 0.5;
            (
                [ $_->{x2},
                  $_->{y2},
                ],
                [ $_->{x2} + floor( 0.5 + arrow_length * sin $ccw_angle ),
                  $_->{y2} + floor( 0.5 + arrow_length * cos $ccw_angle )
                ],
                [ $_->{x2} + floor( 0.5 + arrow_length * 0.75 * sin $angle ),
                  $_->{y2} + floor( 0.5 + arrow_length * 0.75 * cos $angle )
                ],
                [ $_->{x2} + floor( 0.5 + arrow_length * sin $cw_angle ),
                  $_->{y2} + floor( 0.5 + arrow_length * cos $cw_angle )
                ],
                [ $_->{x2},
                  $_->{y2},
                ],
            );
        };

#        my $l;
#        my @colors = qw( #ffe0e0 #e0ffe0 #e0e0ff #e0e0e0 #c0c0c0 );
#        for ( reverse @arrowhead_points ) {
#            if ( $l ) {
#                $i->line(
#                    x1 => $l->[0],
#                    y1 => $l->[1],
#                    x2 => $_->[0],
#                    y2 => $_->[1],
#                    color => shift @colors,
#                    aa => 0,
#                );
#            }
#            $l = $_;
#        }

        $i->polygon(
            points => \@arrowhead_points,
            aa     => 0,
            color => $_->{fontcolor},
        );

        $i->string(
            text  => $_->{label},
            font  => $_->{font},
            x     => $_->{lx},
            y     => $_->{ly} + $_->{label_metrics}->{b_offs},
            color => $_->{fontcolor},
            align => 1,
            aa    => 1,
        );
#$i->line(
#    x1 => $_->{lx},
#    y1 => $_->{ly},
#    x2 => $_->{lx} + 10,
#    y2 => $_->{ly},
#    aa => 0,
#    color => "#000000",
#);
#$i->line(
#    x1 => $_->{lx},
#    y1     => $_->{ly} + $_->{label_metrics}->{b_offs},
#    x2 => $_->{lx} + 10,
#    y2     => $_->{ly} + $_->{label_metrics}->{b_offs},
#    aa => 0,
#    color => "#000000",
#);
    }

    return $i;
}

sub render_to_file {
    my $self = shift;
    my $options = @_ > 2 && ref $_[-1] eq "HASH" ? pop : {};
    my ( $sequence, $fn, $type ) = @_;

    my $i = $self->_render( $sequence, $options );
    $i->write( file => $fn, defined $type ? ( type => $type ) : () )
        or die $i->errstr, ": $fn\n";
}

=item render

    $renderer->render( $s, "png" );

Given a layed out sequence, render it and return it.

Lays out image if not layed out.

=cut

sub render {
    my $self = shift;
    my $options = @_ > 1 && ref $_[-1] eq "HASH" ? pop : {};
    my ( $sequence, $type ) = @_;

    my $i = $self->_render( $sequence, $options );
    $i->write( data => \(my $data), type => $type )
        or die $i->errstr, " rendering $type image\n";
    return \$data;
}

=back

=head2 Methods called by the layout engine

=over

=cut

=item string_metrics

Returns the bounding box for a string:

    {
        w     => $width,
        h     => $height,
        xoffs => $x_offset,
        yoffs => $y_offset,
        font  => $font_handle,
    }

The height is normalized for the entire font so that the strings
will always line up.

=cut

sub string_metrics {
    my $self = shift;
    my ( %options ) = @_;

    my $font = $options{Font};
    $font ||= $self->_default_font;

    my (
        $neg_width,
        $global_descent,
        $pos_width,
        $global_ascent,
        $descent,
        $ascent,
    ) = $font->bounding_box( string => $options{string} );

    ## Fudge this.
    $global_ascent -= 2;

    my $s = {
        w      => $pos_width     - $neg_width,
        h      => $global_ascent - $global_descent,
        b_offs => $global_ascent,
        x_offs => $neg_width,
        y_offs => 0,
        font   => $font,
        color  => Imager::Color->new(
            defined $options{color} ? $options{color} : '#000000'
        ),
    };

    return $s;
}


sub _default_font {
    my $self = shift;

    ## TODO: implement mulitplatform and font path searching
    $self->{_DefaultFont} ||= do {
        my $fontfile = "verdana.ttf";
#        file  => "/usr/share/fonts/default/Type1/c059013l.pfb",
        my $font = Imager::Font->new(
            file  => $fontfile,
            size  => 14,
            color => "#000000",
            aa    => 1,
        );
        die "Unable to load font '$fontfile'\n"
            unless defined $font;
        $font;
    };
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
