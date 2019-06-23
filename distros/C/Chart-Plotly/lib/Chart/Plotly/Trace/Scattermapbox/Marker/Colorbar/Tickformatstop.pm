package Chart::Plotly::Trace::Scattermapbox::Marker::Colorbar::Tickformatstop;
use Moose;
use MooseX::ExtraArgs;
use Moose::Util::TypeConstraints qw(enum union);
if ( !defined Moose::Util::TypeConstraints::find_type_constraint('PDL') ) {
    Moose::Util::TypeConstraints::type('PDL');
}

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

Chart::Plotly::Trace::Scattermapbox::Marker::Colorbar::Tickformatstop - This attribute is one of the possible options for the trace scattermapbox.

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
