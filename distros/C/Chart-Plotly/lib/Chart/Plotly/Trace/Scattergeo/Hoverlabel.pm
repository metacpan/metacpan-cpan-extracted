package Chart::Plotly::Trace::Scattergeo::Hoverlabel;
use Moose;
use MooseX::ExtraArgs;
use Moose::Util::TypeConstraints qw(enum union);
if ( !defined Moose::Util::TypeConstraints::find_type_constraint('PDL') ) {
    Moose::Util::TypeConstraints::type('PDL');
}

use Chart::Plotly::Trace::Scattergeo::Hoverlabel::Font;

our $VERSION = '0.042';    # VERSION

# ABSTRACT: This attribute is one of the possible options for the trace scattergeo.

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
    is            => "rw",
    isa           => union( [ enum( [ "left", "right", "auto" ] ), "ArrayRef" ] ),
    documentation =>
      "Sets the horizontal alignment of the text content within hover label box. Has an effect only if the hover label text spans more two or more lines",
);

has alignsrc => ( is            => "rw",
                  isa           => "Str",
                  documentation => "Sets the source reference on Chart Studio Cloud for `align`.",
);

has bgcolor => ( is            => "rw",
                 isa           => "Str|ArrayRef[Str]",
                 documentation => "Sets the background color of the hover labels for this trace",
);

has bgcolorsrc => ( is            => "rw",
                    isa           => "Str",
                    documentation => "Sets the source reference on Chart Studio Cloud for `bgcolor`.",
);

has bordercolor => ( is            => "rw",
                     isa           => "Str|ArrayRef[Str]",
                     documentation => "Sets the border color of the hover labels for this trace.",
);

has bordercolorsrc => ( is            => "rw",
                        isa           => "Str",
                        documentation => "Sets the source reference on Chart Studio Cloud for `bordercolor`.",
);

has font => ( is  => "rw",
              isa => "Maybe[HashRef]|Chart::Plotly::Trace::Scattergeo::Hoverlabel::Font", );

has namelength => (
    is            => "rw",
    isa           => "Int|ArrayRef[Int]",
    documentation =>
      "Sets the default length (in number of characters) of the trace name in the hover labels for all traces. -1 shows the whole name regardless of length. 0-3 shows the first 0-3 characters, and an integer >3 will show the whole name if it is less than that many characters, but if it is longer, will truncate to `namelength - 3` characters and add an ellipsis.",
);

has namelengthsrc => ( is            => "rw",
                       isa           => "Str",
                       documentation => "Sets the source reference on Chart Studio Cloud for `namelength`.",
);

__PACKAGE__->meta->make_immutable();
1;

__END__

=pod

=encoding utf-8

=head1 NAME

Chart::Plotly::Trace::Scattergeo::Hoverlabel - This attribute is one of the possible options for the trace scattergeo.

=head1 VERSION

version 0.042

=head1 SYNOPSIS

 use Chart::Plotly;
 use Chart::Plotly::Plot;
 use Chart::Plotly::Trace::Scattergeo;
 use Chart::Plotly::Trace::Scattergeo::Marker;
 my $scattergeo = Chart::Plotly::Trace::Scattergeo->new(
     mode => 'markers+text',
     text => [ 'Mount Everest', 'K2',      'Kangchenjunga', 'Lhotse', 'Makalu', 'Cho Oyu',
               'Dhaulagiri I',  'Manaslu', 'Nanga Parbat',  'Annapurna I'
     ],
     lon => [ 86.9252777778, 76.5133333333, 88.1475,       86.9330555556, 87.0888888889, 86.6608333333,
              83.4930555556, 84.5597222222, 74.5891666667, 83.8202777778
     ],
     lat => [ 27.9880555556, 35.8813888889, 27.7033333333, 27.9616666667, 27.8897222222, 28.0941666667,
              28.6966666667, 28.55,         35.2372222222, 28.5955555556
     ],
     name => "Highest mountains
         https://en.wikipedia.org/wiki/List_of_highest_mountains_on_Earth",
     textposition => [ 'top right',
                       'top center',
                       'bottom center',
                       'bottom left',
                       'right',
                       'left',
                       'left',
                       'right',
                       'bottom center',
                       'top center'
     ],
     marker => Chart::Plotly::Trace::Scattergeo::Marker->new(
                                                    size  => 7,
                                                    color => [
                                                        '#bebada', '#fdb462', '#fb8072', '#d9d9d9', '#bc80bd', '#b3de69',
                                                        '#8dd3c7', '#80b1d3', '#fccde5', '#ffffb3'
                                                    ]
     )
 );
 
 my $plot = Chart::Plotly::Plot->new( traces => [$scattergeo],
                                      layout => { title => 'Mountains',
                                                  geo   => { scope => 'asia', }
                                      }
 );
 Chart::Plotly::show_plot($plot);

=head1 DESCRIPTION

This attribute is part of the possible options for the trace scattergeo.

This file has been autogenerated from the official plotly.js source.

If you like Plotly, please support them: L<https://plot.ly/> 
Open source announcement: L<https://plot.ly/javascript/open-source-announcement/>

Full reference: L<https://plot.ly/javascript/reference/#scattergeo>

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

Sets the source reference on Chart Studio Cloud for `align`.

=item * bgcolor

Sets the background color of the hover labels for this trace

=item * bgcolorsrc

Sets the source reference on Chart Studio Cloud for `bgcolor`.

=item * bordercolor

Sets the border color of the hover labels for this trace.

=item * bordercolorsrc

Sets the source reference on Chart Studio Cloud for `bordercolor`.

=item * font

=item * namelength

Sets the default length (in number of characters) of the trace name in the hover labels for all traces. -1 shows the whole name regardless of length. 0-3 shows the first 0-3 characters, and an integer >3 will show the whole name if it is less than that many characters, but if it is longer, will truncate to `namelength - 3` characters and add an ellipsis.

=item * namelengthsrc

Sets the source reference on Chart Studio Cloud for `namelength`.

=back

=head1 AUTHOR

Pablo Rodríguez González <pablo.rodriguez.gonzalez@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2022 by Pablo Rodríguez González.

This is free software, licensed under:

  The MIT (X11) License

=cut
