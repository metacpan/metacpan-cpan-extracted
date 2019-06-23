package Chart::Plotly::Trace::Scattermapbox::Hoverlabel;
use Moose;
use MooseX::ExtraArgs;
use Moose::Util::TypeConstraints qw(enum union);
if ( !defined Moose::Util::TypeConstraints::find_type_constraint('PDL') ) {
    Moose::Util::TypeConstraints::type('PDL');
}

use Chart::Plotly::Trace::Scattermapbox::Hoverlabel::Font;

our $VERSION = '0.027';    # VERSION

# ABSTRACT: This attribute is one of the possible options for the trace scattermapbox.

sub TO_JSON {
    my $self       = shift;
    my $extra_args = $self->extra_args // {};
    my $meta       = $self->meta;
    my %hash       = %$self;
    for my $name ( sort keys %hash ) {
        my $attr = $meta->get_attribute($name);
        if ( defined $attr ) {
            my $value = $hash{$name};
            my $type  = $attr->type_constraint;
            if ( $type && $type->equals('Bool') ) {
                $hash{$name} = $value ? \1 : \0;
            }
        }
    }
    %hash = ( %hash, %$extra_args );
    delete $hash{'extra_args'};
    if ( $self->can('type') && ( !defined $hash{'type'} ) ) {
        $hash{type} = $self->type();
    }
    return \%hash;
}

has align => (
    is  => "rw",
    isa => union( [ enum( [ "left", "right", "auto" ] ), "ArrayRef" ] ),
    documentation =>
      "Sets the horizontal alignment of the text content within hover label box. Has an effect only if the hover label text spans more two or more lines",
);

has alignsrc => ( is            => "rw",
                  isa           => "Str",
                  documentation => "Sets the source reference on plot.ly for  align .",
);

has bgcolor => ( is            => "rw",
                 isa           => "Str|ArrayRef[Str]",
                 documentation => "Sets the background color of the hover labels for this trace",
);

has bgcolorsrc => ( is            => "rw",
                    isa           => "Str",
                    documentation => "Sets the source reference on plot.ly for  bgcolor .",
);

has bordercolor => ( is            => "rw",
                     isa           => "Str|ArrayRef[Str]",
                     documentation => "Sets the border color of the hover labels for this trace.",
);

has bordercolorsrc => ( is            => "rw",
                        isa           => "Str",
                        documentation => "Sets the source reference on plot.ly for  bordercolor .",
);

has font => ( is  => "rw",
              isa => "Maybe[HashRef]|Chart::Plotly::Trace::Scattermapbox::Hoverlabel::Font", );

has namelength => (
    is  => "rw",
    isa => "Int|ArrayRef[Int]",
    documentation =>
      "Sets the default length (in number of characters) of the trace name in the hover labels for all traces. -1 shows the whole name regardless of length. 0-3 shows the first 0-3 characters, and an integer >3 will show the whole name if it is less than that many characters, but if it is longer, will truncate to `namelength - 3` characters and add an ellipsis.",
);

has namelengthsrc => ( is            => "rw",
                       isa           => "Str",
                       documentation => "Sets the source reference on plot.ly for  namelength .",
);

__PACKAGE__->meta->make_immutable();
1;

__END__

=pod

=encoding utf-8

=head1 NAME

Chart::Plotly::Trace::Scattermapbox::Hoverlabel - This attribute is one of the possible options for the trace scattermapbox.

=head1 VERSION

version 0.027

=head1 SYNOPSIS

 use Chart::Plotly;
 use Chart::Plotly::Plot;
 use Chart::Plotly::Trace::Scattermapbox;
 use Chart::Plotly::Trace::Scattermapbox::Marker;
 my $mapbox_access_token =
   'Insert your access token here';
 my $scattermapbox = Chart::Plotly::Trace::Scattermapbox->new(
                 mode => 'markers',
                 text => [ "The coffee bar",
                           "Bistro Bohem", "Black Cat", "Snap", "Columbia Heights Coffee",
                           "Azi's Cafe", "Blind Dog Cafe",
                           "Le Caprice", "Filter", "Peregrine", "Tryst", "The Coupe", "Big Bear Cafe"
                 ],
                 lon => [ '-77.02827', '-77.02013', '-77.03155', '-77.04227', '-77.02854',  '-77.02419',
                          '-77.02518', '-77.03304', '-77.04509', '-76.99656', '-77.042438', '-77.02821',
                          '-77.01239'
                 ],
                 lat => [ '38.91427', '38.91538', '38.91458', '38.92239', '38.93222', '38.90842', '38.91931', '38.93260',
                          '38.91368', '38.88516', '38.921894', '38.93206', '38.91275'
                 ],
                 marker => Chart::Plotly::Trace::Scattermapbox::Marker->new( size => 9 ),
 );
 my $plot = Chart::Plotly::Plot->new( traces => [$scattermapbox],
                                      layout => { autosize  => 'True',
                                                  hovermode => 'closest',
                                                  mapbox    => {
                                                              accesstoken => $mapbox_access_token,
                                                              bearing     => 0,
                                                              center      => {
                                                                          lat => 38.92,
                                                                          lon => -77.07
                                                              },
                                                              pitch => 0,
                                                              zoom  => 10
                                                  }
                                      }
 );
 Chart::Plotly::show_plot($plot);

=head1 DESCRIPTION

This attribute is part of the possible options for the trace scattermapbox.

This file has been autogenerated from the official plotly.js source.

If you like Plotly, please support them: L<https://plot.ly/> 
Open source announcement: L<https://plot.ly/javascript/open-source-announcement/>

Full reference: L<https://plot.ly/javascript/reference/#scattermapbox>

=head1 DISCLAIMER

This is an unofficial Plotly Perl module. Currently I'm not affiliated in any way with Plotly. 
But I think plotly.js is a great library and I want to use it with perl.

=head1 METHODS

=head2 TO_JSON

Serialize the trace to JSON. This method should be called only by L<JSON> serializer.

=head1 ATTRIBUTES

=over

=item * align

Sets the horizontal alignment of the text content within hover label box. Has an effect only if the hover label text spans more two or more lines

=item * alignsrc

Sets the source reference on plot.ly for  align .

=item * bgcolor

Sets the background color of the hover labels for this trace

=item * bgcolorsrc

Sets the source reference on plot.ly for  bgcolor .

=item * bordercolor

Sets the border color of the hover labels for this trace.

=item * bordercolorsrc

Sets the source reference on plot.ly for  bordercolor .

=item * font

=item * namelength

Sets the default length (in number of characters) of the trace name in the hover labels for all traces. -1 shows the whole name regardless of length. 0-3 shows the first 0-3 characters, and an integer >3 will show the whole name if it is less than that many characters, but if it is longer, will truncate to `namelength - 3` characters and add an ellipsis.

=item * namelengthsrc

Sets the source reference on plot.ly for  namelength .

=back

=head1 AUTHOR

Pablo Rodríguez González <pablo.rodriguez.gonzalez@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Pablo Rodríguez González.

This is free software, licensed under:

  The MIT (X11) License

=cut
