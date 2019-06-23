package Chart::Plotly::Trace::Barpolar::Hoverlabel;
use Moose;
use MooseX::ExtraArgs;
use Moose::Util::TypeConstraints qw(enum union);
if ( !defined Moose::Util::TypeConstraints::find_type_constraint('PDL') ) {
    Moose::Util::TypeConstraints::type('PDL');
}

use Chart::Plotly::Trace::Barpolar::Hoverlabel::Font;

our $VERSION = '0.027';    # VERSION

# ABSTRACT: This attribute is one of the possible options for the trace barpolar.

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
              isa => "Maybe[HashRef]|Chart::Plotly::Trace::Barpolar::Hoverlabel::Font", );

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

Chart::Plotly::Trace::Barpolar::Hoverlabel - This attribute is one of the possible options for the trace barpolar.

=head1 VERSION

version 0.027

=head1 SYNOPSIS

 use Chart::Plotly;
 use Chart::Plotly::Trace::Barpolar;
 use Chart::Plotly::Plot;
 
 # Example from https://github.com/plotly/plotly.js/blob/235fe5b214a576d5749ab4c2aaf625dbf7138d63/test/image/mocks/polar_wind-rose.json
 my $trace1 = Chart::Plotly::Trace::Barpolar->new(
     r    => [ 77.5,    72.5,  70.0,   45.0,  22.5,    42.5,  40.0,   62.5 ],
     t    => [ 'North', 'N-E', 'East', 'S-E', 'South', 'S-W', 'West', 'N-W' ],
     name => '11-14 m/s',
     marker => { color => 'rgb(106,81,163)' },
 );
 
 my $trace2 = {
     r    => [ 57.5,    50.0,  45.0,   35.0,  20.0,    22.5,  37.5,   55.0 ],
     t    => [ 'North', 'N-E', 'East', 'S-E', 'South', 'S-W', 'West', 'N-W' ],
     name => '8-11 m/s',
     marker => { color => 'rgb(158,154,200)' },
     type   => 'barpolar'
 };
 
 my $trace3 = {
     r    => [ 40.0,    30.0,  30.0,   35.0,  7.5,     7.5,   32.5,   40.0 ],
     t    => [ 'North', 'N-E', 'East', 'S-E', 'South', 'S-W', 'West', 'N-W' ],
     name => '5-8 m/s',
     marker => { color => 'rgb(203,201,226)' },
     type   => 'barpolar'
 };
 
 my $trace4 = {
     r    => [ 20.0,    7.5,   15.0,   22.5,  2.5,     2.5,   12.5,   22.5 ],
     t    => [ 'North', 'N-E', 'East', 'S-E', 'South', 'S-W', 'West', 'N-W' ],
     name => '< 5 m/s',
     marker => { color => 'rgb(242,240,247)' },
     type   => 'barpolar'
 };
 
 my $plot = Chart::Plotly::Plot->new(
     traces => [ $trace1, $trace2, $trace3, $trace4 ],
     layout => {
         title  => 'Wind Speed Distribution in Laurel, NE',
         font   => { size => 16 },
         legend => { font => { size => 16 } },
         polar  => {
             radialaxis => { ticksuffix => '%', angle => 45, dtick => 20 },
             barmode    => "overlay",
             angularaxis => { direction => "clockwise" },
             bargap      => 0
         }
       }
 
 );
 
 Chart::Plotly::show_plot($plot);

=head1 DESCRIPTION

This attribute is part of the possible options for the trace barpolar.

This file has been autogenerated from the official plotly.js source.

If you like Plotly, please support them: L<https://plot.ly/> 
Open source announcement: L<https://plot.ly/javascript/open-source-announcement/>

Full reference: L<https://plot.ly/javascript/reference/#barpolar>

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
