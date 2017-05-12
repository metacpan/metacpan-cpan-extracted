package CairoX::Pager;
use warnings;
use strict;
use base qw(Class::Accessor::Fast);
__PACKAGE__->mk_accessors( qw(
    id
    surface 
    context 
    config 
    page_spec 
    type
) );

use Cairo;
use File::Spec;

=head1 NAME

CairoX::Pager - pager for pdf , image surface backend.

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

=head1 DESCRIPTION

L<Cairo::PdfSurface> supports pages , but image surface doesn't.  this module
page both pdf or image for you. for image type surface , we export page to a
directory and give them a formatted name on C<finish_page> method.  for pdf
surface , we create pdf document at start , and call cairo context C<show_page>
function to start a new page.

* svg , ps type surface are not supported yet.

=head1 SYNOPSIS

export pages pdf:

    my $pager = CairoX::Pager->new(
        pdf => { filename => $filepath },
        page_spec => { width =>  , height => },
    );

    for ( ... ) {
        $pager->new_page( );

        my $surface = $pager->surface();   # get cairo surface 
        my $cr = $pager->context();    # get cairo context


        # draw something


        $pager->finish_page( );
    }

    $pager->finish();

export pages as svg :

    my $pager = CairoX::Pager->new( 
        svg => { 
            directory => $path,
            filename_format => "%04d.png",
        },
        page_spec => { width =>  , height => },
    );

export pages as png :

    my $pager = CairoX::Pager->new( 
        png => { 
            directory => $path,
            filename_format => "%04d.png",
            dpi => 600,
        },
        page_spec => { width =>  , height => },
    );

=head1 FUNCTIONS

=head2 new 

=cut

sub new {
    my $class = shift;
    my %args = @_;
    my $self = bless {}, $class;
    $self->SUPER::new;

    die unless $args{png} or $args{pdf} or $args{svg} or $args{ps} ;

    die unless $args{page_spec};

    $self->id( 0 );
    $self->config( $args{png} || $args{pdf} || $args{svg} || $args{ps} );
    $self->page_spec(  $args{page_spec} );
    $self->type( 
        defined $args{png} ? 'png' : 
            defined $args{pdf} ? 'pdf' :
                defined $args{svg} ? 'svg' : undef 
    );

    if( $self->type eq 'pdf' || $self->type eq 'ps' ) {
        my $class = 'Cairo::' . ucfirst( $self->type ) . 'Surface';
        my $surface = $class->create(
            $self->config->{filename},
            $self->page_spec->{width},
            $self->page_spec->{height},
        );

        my $context = Cairo::Context->create($surface);
        $self->surface( $surface );
        $self->context( $context );
        $self->fill_white();
    }
    return $self;
}


sub fill_white {
    my $self = shift;
    my $context = $self->context;
    $context->rectangle( 
        0, 0,
        $self->page_spec->{width},
        $self->page_spec->{height}
    );
    $context->set_source_rgba( 1, 1, 1, 1 );
    $context->fill;
}

=head2 current_filename

=cut

sub current_filename {
    my $self = shift;
    if( $self->type eq 'png' ) {
        return File::Spec->join(
                    $self->config->{directory},
                    sprintf( $self->config->{filename_format} , $self->id ) 
        );
    }
    elsif( $self->type eq 'pdf' ) {
        return $self->config->{filename};
    }
}

=head2 new_page

=cut

sub new_page {
    my $self = shift;
    $self->id(  $self->id + 1 );

    if( $self->type eq 'png' ) {
        my $surface = Cairo::ImageSurface->create( 'argb32',
            $self->page_spec->{width},
            $self->page_spec->{height},
        );
        $self->surface( $surface );

        my $context = Cairo::Context->create($surface);
        $self->context( $context );

        $self->fill_white();
    }
    elsif( $self->type eq 'svg' ) {
        my $surface = Cairo::SvgSurface->create( 
            $self->current_filename ,
            $self->page_spec->{width},
            $self->page_spec->{height},
        );
        $self->surface( $surface );

        my $context = Cairo::Context->create($surface);
        $self->context( $context );

        $self->fill_white();

    }
}


=head2 finish_page

=cut

sub finish_page {
    my $self = shift;
    if( $self->type eq 'png' ) {
        my $filename = $self->current_filename;
        $self->surface->write_to_png( $filename );
        $self->surface->finish;  # drop references

        $self->surface( undef );
        $self->context( undef );

        # XXX: resolution option
        # AIINK::Imager->set_file_res( $filename , $self->config->{dpi} );
    }
    elsif( $self->type eq 'svg' ) {
        $self->surface( undef );
        $self->context( undef );
    }
    elsif( $self->type eq 'pdf' ) {
        $self->context->show_page();
        $self->surface->flush();
    }
}


=head2 finish 

=cut

sub finish {
    my $self = shift;
    if( $self->type eq 'pdf' ) {
        $self->surface->flush();
        $self->surface->finish();
        $self->context( undef );
        $self->surface( undef );
    }
}


=head1 AUTHOR

c9s, C<< <cornelius.howl at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-cairox-pager at
rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CairoX-Pager>.  I will be
notified, and then you'll automatically be notified of progress on your bug as
I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc CairoX::Pager

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=CairoX-Pager>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/CairoX-Pager>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/CairoX-Pager>

=item * Search CPAN

L<http://search.cpan.org/dist/CairoX-Pager/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 c9s, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of CairoX::Pager
