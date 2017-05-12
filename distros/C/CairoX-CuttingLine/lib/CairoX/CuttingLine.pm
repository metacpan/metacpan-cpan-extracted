package CairoX::CuttingLine;

use warnings;
use strict;

=head1 NAME

CairoX::CuttingLine - draw cutting line to cairo surface

=head1 VERSION

Version 0.05

=cut

our $VERSION = '0.05';


=head1 SYNOPSIS

to use CairoX::CuttingLine to render cutting lines to a canvas:

    use CairoX::CuttingLine;

we need to provide L<Cairo::Context> for L<CairoX::CuttingLine> method new.

    my $surf = Cairo::ImageSurface->create ('argb32', 200 , 200 );
    my $cr = Cairo::Context->create ($surf);

set Cairo::Context object

    my $page = CairoX::CuttingLine->new( $cr );

or by cr accessor

    $page->cr( $cr );

    $page->set(  x => 10 , y => 10  );
    $page->size( width => 100 , width => 120 );
    $page->length( 10 );
    $page->line_width( 3 );
    $page->color( 1, 1, 1, 1 );    # for set_source_rgba
    $page->stroke();

=head1 DESCRIPTION

CairoX::CuttingLine draws cutting line like this:

    |       |
   -+       +-
      IMAGE
   -+       +-
    |       |

=head1 FUNCTIONS

=cut

sub new {
    my $class = shift;
    my $self = {};
    bless $self , $class;
    $self->{cr} = shift;
    return $self;
}

sub cr {
    my $self = shift;
    $self->{cr} = shift if @_;
    $self->{cr};
}

sub set {
    my $self = shift;
    $self->{p} = { @_ } if @_;
    return $self->{p};
}

sub length {
    my $self = shift;
    $self->{length} = shift if @_;
    $self->{length};
}

sub size {
    my $self = shift;
    $self->{size} = { @_ } if @_;
    $self->{size};
}

sub color {
    my $self = shift;
    $self->{color} = [ @_ ] if @_;
    $self->{color};
}

sub line_width {
    my $self = shift;
    $self->{line_width} = shift if @_;
    $self->{line_width};
}

sub stroke {
    my $self = shift;
    my $cr = $self->{cr};
    $cr->save;

    my $color = $self->{color};
    $color ||= [1,1,1,1];

    $cr->set_source_rgba( @$color );
    $cr->set_line_width( $self->line_width );
    my $pos = $self->set;

    my $s = $self->size;
    my $line_len = $self->length;

    for my $p ( 0 .. 3 ) {

        my ( $c_x, $c_y ) = ( $pos->{x}, $pos->{y} );
        if( $p & 1 ) {
            $c_x += $s->{width};
        }
        if( $p & 2 ) {
            $c_y += $s->{height};
        }

        $cr->move_to( $c_x , $c_y );
        $cr->line_to(
            $c_x + ( $p & 1 ? $line_len : -$line_len ),
            $c_y
        );

        $cr->move_to( $c_x , $c_y );
        $cr->line_to(
            $c_x,
            $c_y + ( $p & 2 ? $line_len : -$line_len ),
        );
        $cr->stroke();
    }
    $cr->restore;
}



=head1 AUTHOR

Cornelius, C<< <cornelius.howl at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-cairo-cuttingline at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Cairo-CuttingLine>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc CairoX::CuttingLine


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Cairo-CuttingLine>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Cairo-CuttingLine>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Cairo-CuttingLine>

=item * Search CPAN

L<http://search.cpan.org/dist/Cairo-CuttingLine/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Cornelius, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of CairoX::CuttingLine
