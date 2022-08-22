package Chart::Plotly::Trace::Barpolar::Marker::Pattern;
use Moose;
use MooseX::ExtraArgs;
use Moose::Util::TypeConstraints qw(enum union);
if ( !defined Moose::Util::TypeConstraints::find_type_constraint('PDL') ) {
    Moose::Util::TypeConstraints::type('PDL');
}

our $VERSION = '0.042';    # VERSION

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

has bgcolor => (
    is            => "rw",
    isa           => "Str|ArrayRef[Str]",
    documentation =>
      "When there is no colorscale sets the color of background pattern fill. Defaults to a `marker.color` background when `fillmode` is *overlay*. Otherwise, defaults to a transparent background.",
);

has bgcolorsrc => ( is            => "rw",
                    isa           => "Str",
                    documentation => "Sets the source reference on Chart Studio Cloud for `bgcolor`.",
);

has description => ( is      => "ro",
                     default => "Sets the pattern within the marker.", );

has fgcolor => (
    is            => "rw",
    isa           => "Str|ArrayRef[Str]",
    documentation =>
      "When there is no colorscale sets the color of foreground pattern fill. Defaults to a `marker.color` background when `fillmode` is *replace*. Otherwise, defaults to dark grey or white to increase contrast with the `bgcolor`.",
);

has fgcolorsrc => ( is            => "rw",
                    isa           => "Str",
                    documentation => "Sets the source reference on Chart Studio Cloud for `fgcolor`.",
);

has fgopacity => (
    is            => "rw",
    isa           => "Num",
    documentation =>
      "Sets the opacity of the foreground pattern fill. Defaults to a 0.5 when `fillmode` is *overlay*. Otherwise, defaults to 1.",
);

has fillmode => (
          is            => "rw",
          isa           => enum( [ "replace", "overlay" ] ),
          documentation => "Determines whether `marker.color` should be used as a default to `bgcolor` or a `fgcolor`.",
);

has shape => (
            is            => "rw",
            isa           => union( [ enum( [ "", "/", "\\", "x", "-", "|", "+", "." ] ), "ArrayRef" ] ),
            documentation => "Sets the shape of the pattern fill. By default, no pattern is used for filling the area.",
);

has shapesrc => ( is            => "rw",
                  isa           => "Str",
                  documentation => "Sets the source reference on Chart Studio Cloud for `shape`.",
);

has size => (
    is            => "rw",
    isa           => "Num|ArrayRef[Num]",
    documentation =>
      "Sets the size of unit squares of the pattern fill in pixels, which corresponds to the interval of repetition of the pattern.",
);

has sizesrc => ( is            => "rw",
                 isa           => "Str",
                 documentation => "Sets the source reference on Chart Studio Cloud for `size`.",
);

has solidity => (
    is            => "rw",
    isa           => "Num|ArrayRef[Num]",
    documentation =>
      "Sets the solidity of the pattern fill. Solidity is roughly the fraction of the area filled by the pattern. Solidity of 0 shows only the background color without pattern and solidty of 1 shows only the foreground color without pattern.",
);

has soliditysrc => ( is            => "rw",
                     isa           => "Str",
                     documentation => "Sets the source reference on Chart Studio Cloud for `solidity`.",
);

__PACKAGE__->meta->make_immutable();
1;

__END__

=pod

=encoding utf-8

=head1 NAME

Chart::Plotly::Trace::Barpolar::Marker::Pattern - This attribute is one of the possible options for the trace barpolar.

=head1 VERSION

version 0.042

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

=item * bgcolor

When there is no colorscale sets the color of background pattern fill. Defaults to a `marker.color` background when `fillmode` is *overlay*. Otherwise, defaults to a transparent background.

=item * bgcolorsrc

Sets the source reference on Chart Studio Cloud for `bgcolor`.

=item * description

=item * fgcolor

When there is no colorscale sets the color of foreground pattern fill. Defaults to a `marker.color` background when `fillmode` is *replace*. Otherwise, defaults to dark grey or white to increase contrast with the `bgcolor`.

=item * fgcolorsrc

Sets the source reference on Chart Studio Cloud for `fgcolor`.

=item * fgopacity

Sets the opacity of the foreground pattern fill. Defaults to a 0.5 when `fillmode` is *overlay*. Otherwise, defaults to 1.

=item * fillmode

Determines whether `marker.color` should be used as a default to `bgcolor` or a `fgcolor`.

=item * shape

Sets the shape of the pattern fill. By default, no pattern is used for filling the area.

=item * shapesrc

Sets the source reference on Chart Studio Cloud for `shape`.

=item * size

Sets the size of unit squares of the pattern fill in pixels, which corresponds to the interval of repetition of the pattern.

=item * sizesrc

Sets the source reference on Chart Studio Cloud for `size`.

=item * solidity

Sets the solidity of the pattern fill. Solidity is roughly the fraction of the area filled by the pattern. Solidity of 0 shows only the background color without pattern and solidty of 1 shows only the foreground color without pattern.

=item * soliditysrc

Sets the source reference on Chart Studio Cloud for `solidity`.

=back

=head1 AUTHOR

Pablo Rodríguez González <pablo.rodriguez.gonzalez@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2022 by Pablo Rodríguez González.

This is free software, licensed under:

  The MIT (X11) License

=cut
