package Chart::Plotly::Trace::Barpolar::Marker::Colorbar::Tickformatstop;
use Moose;
use MooseX::ExtraArgs;
use Moose::Util::TypeConstraints qw(enum union);
if ( !defined Moose::Util::TypeConstraints::find_type_constraint('PDL') ) {
    Moose::Util::TypeConstraints::type('PDL');
}

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

has dtickrange => (
    is  => "rw",
    isa => "ArrayRef|PDL",
    documentation =>
      "range [*min*, *max*], where *min*, *max* - dtick values which describe some zoom level, it is possible to omit *min* or *max* value by passing *null*",
);

has enabled => (
        is  => "rw",
        isa => "Bool",
        documentation =>
          "Determines whether or not this stop is used. If `false`, this stop is ignored even within its `dtickrange`.",
);

has name => (
    is  => "rw",
    isa => "Str",
    documentation =>
      "When used in a template, named items are created in the output figure in addition to any items the figure already has in this array. You can modify these items in the output figure by making your own item with `templateitemname` matching this `name` alongside your modifications (including `visible: false` or `enabled: false` to hide it). Has no effect outside of a template.",
);

has templateitemname => (
    is  => "rw",
    isa => "Str",
    documentation =>
      "Used to refer to a named item in this array in the template. Named items from the template will be created even without a matching item in the input figure, but you can modify one by making an item with `templateitemname` matching its `name`, alongside your modifications (including `visible: false` or `enabled: false` to hide it). If there is no template or no matching item, this item will be hidden unless you explicitly show it with `visible: true`.",
);

has value => ( is            => "rw",
               isa           => "Str",
               documentation => "string - dtickformat for described zoom level, the same as *tickformat*",
);

__PACKAGE__->meta->make_immutable();
1;

__END__

=pod

=encoding utf-8

=head1 NAME

Chart::Plotly::Trace::Barpolar::Marker::Colorbar::Tickformatstop - This attribute is one of the possible options for the trace barpolar.

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

=item * dtickrange

range [*min*, *max*], where *min*, *max* - dtick values which describe some zoom level, it is possible to omit *min* or *max* value by passing *null*

=item * enabled

Determines whether or not this stop is used. If `false`, this stop is ignored even within its `dtickrange`.

=item * name

When used in a template, named items are created in the output figure in addition to any items the figure already has in this array. You can modify these items in the output figure by making your own item with `templateitemname` matching this `name` alongside your modifications (including `visible: false` or `enabled: false` to hide it). Has no effect outside of a template.

=item * templateitemname

Used to refer to a named item in this array in the template. Named items from the template will be created even without a matching item in the input figure, but you can modify one by making an item with `templateitemname` matching its `name`, alongside your modifications (including `visible: false` or `enabled: false` to hide it). If there is no template or no matching item, this item will be hidden unless you explicitly show it with `visible: true`.

=item * value

string - dtickformat for described zoom level, the same as *tickformat*

=back

=head1 AUTHOR

Pablo Rodríguez González <pablo.rodriguez.gonzalez@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Pablo Rodríguez González.

This is free software, licensed under:

  The MIT (X11) License

=cut
