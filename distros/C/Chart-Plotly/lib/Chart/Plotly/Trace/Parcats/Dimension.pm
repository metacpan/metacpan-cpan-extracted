package Chart::Plotly::Trace::Parcats::Dimension;
use Moose;
use MooseX::ExtraArgs;
use Moose::Util::TypeConstraints qw(enum union);
if ( !defined Moose::Util::TypeConstraints::find_type_constraint('PDL') ) {
    Moose::Util::TypeConstraints::type('PDL');
}

our $VERSION = '0.027';    # VERSION

# ABSTRACT: This attribute is one of the possible options for the trace parcats.

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

has categoryarray => (
    is  => "rw",
    isa => "ArrayRef|PDL",
    documentation =>
      "Sets the order in which categories in this dimension appear. Only has an effect if `categoryorder` is set to *array*. Used with `categoryorder`.",
);

has categoryarraysrc => ( is            => "rw",
                          isa           => "Str",
                          documentation => "Sets the source reference on plot.ly for  categoryarray .",
);

has categoryorder => (
    is  => "rw",
    isa => enum( [ "trace", "category ascending", "category descending", "array" ] ),
    documentation =>
      "Specifies the ordering logic for the categories in the dimension. By default, plotly uses *trace*, which specifies the order that is present in the data supplied. Set `categoryorder` to *category ascending* or *category descending* if order should be determined by the alphanumerical order of the category names. Set `categoryorder` to *array* to derive the ordering from the attribute `categoryarray`. If a category is not found in the `categoryarray` array, the sorting behavior for that attribute will be identical to the *trace* mode. The unspecified categories will follow the categories in `categoryarray`.",
);

has description => ( is      => "ro",
                     default => "The dimensions (variables) of the parallel categories diagram.", );

has displayindex => (
      is            => "rw",
      isa           => "Int",
      documentation => "The display index of dimension, from left to right, zero indexed, defaults to dimension index.",
);

has label => ( is            => "rw",
               isa           => "Str",
               documentation => "The shown name of the dimension.",
);

has ticktext => (
    is  => "rw",
    isa => "ArrayRef|PDL",
    documentation =>
      "Sets alternative tick labels for the categories in this dimension. Only has an effect if `categoryorder` is set to *array*. Should be an array the same length as `categoryarray` Used with `categoryorder`.",
);

has ticktextsrc => ( is            => "rw",
                     isa           => "Str",
                     documentation => "Sets the source reference on plot.ly for  ticktext .",
);

has values => (
    is  => "rw",
    isa => "ArrayRef|PDL",
    documentation =>
      "Dimension values. `values[n]` represents the category value of the `n`th point in the dataset, therefore the `values` vector for all dimensions must be the same (longer vectors will be truncated).",
);

has valuessrc => ( is            => "rw",
                   isa           => "Str",
                   documentation => "Sets the source reference on plot.ly for  values .",
);

has visible => (
              is            => "rw",
              isa           => "Bool",
              documentation => "Shows the dimension when set to `true` (the default). Hides the dimension for `false`.",
);

__PACKAGE__->meta->make_immutable();
1;

__END__

=pod

=encoding utf-8

=head1 NAME

Chart::Plotly::Trace::Parcats::Dimension - This attribute is one of the possible options for the trace parcats.

=head1 VERSION

version 0.027

=head1 SYNOPSIS

 use Chart::Plotly;
 use Chart::Plotly::Trace::Parcats;
 use Chart::Plotly::Plot;
 
 # Example from https://github.com/plotly/plotly.js/blob/7b751009fc9804272316f0bb539ed0386c0858bd/test/image/mocks/parcats_bundled.json
 
 my $trace = Chart::Plotly::Trace::Parcats->new( bundlecolors => 1,
                                                 dimensions   => [
                                                            { label  => 'One',
                                                              values => [ (1) x 2, 2, 1, 2, (1) x 2, 2, 1 ]
                                                            },
                                                            { label  => 'Two',
                                                              values => [ 'A', 'B', 'A', 'B', ('C') x 2, 'A', 'B', 'C' ]
                                                            },
                                                            { label  => 'Three',
                                                              values => [ (11) x 9 ]
                                                            }
                                                 ],
                                                 domain => { x => [ 0.125, 0.625 ],
                                                             y => [ 0.25,  0.75 ]
                                                 },
                                                 line => { color => [ (0) x 2, (1) x 2, 0, 1, (0) x 3 ] }
 );
 
 my $plot = Chart::Plotly::Plot->new( traces => [$trace],
                                      layout => { height => 602,
                                                  margin => { b => 40,
                                                              l => 40,
                                                              r => 40,
                                                              t => 50
                                                  },
                                                  width => 592
                                      }
 );
 
 Chart::Plotly::show_plot($plot);

=head1 DESCRIPTION

This attribute is part of the possible options for the trace parcats.

This file has been autogenerated from the official plotly.js source.

If you like Plotly, please support them: L<https://plot.ly/> 
Open source announcement: L<https://plot.ly/javascript/open-source-announcement/>

Full reference: L<https://plot.ly/javascript/reference/#parcats>

=head1 DISCLAIMER

This is an unofficial Plotly Perl module. Currently I'm not affiliated in any way with Plotly. 
But I think plotly.js is a great library and I want to use it with perl.

=head1 METHODS

=head2 TO_JSON

Serialize the trace to JSON. This method should be called only by L<JSON> serializer.

=head1 ATTRIBUTES

=over

=item * categoryarray

Sets the order in which categories in this dimension appear. Only has an effect if `categoryorder` is set to *array*. Used with `categoryorder`.

=item * categoryarraysrc

Sets the source reference on plot.ly for  categoryarray .

=item * categoryorder

Specifies the ordering logic for the categories in the dimension. By default, plotly uses *trace*, which specifies the order that is present in the data supplied. Set `categoryorder` to *category ascending* or *category descending* if order should be determined by the alphanumerical order of the category names. Set `categoryorder` to *array* to derive the ordering from the attribute `categoryarray`. If a category is not found in the `categoryarray` array, the sorting behavior for that attribute will be identical to the *trace* mode. The unspecified categories will follow the categories in `categoryarray`.

=item * description

=item * displayindex

The display index of dimension, from left to right, zero indexed, defaults to dimension index.

=item * label

The shown name of the dimension.

=item * ticktext

Sets alternative tick labels for the categories in this dimension. Only has an effect if `categoryorder` is set to *array*. Should be an array the same length as `categoryarray` Used with `categoryorder`.

=item * ticktextsrc

Sets the source reference on plot.ly for  ticktext .

=item * values

Dimension values. `values[n]` represents the category value of the `n`th point in the dataset, therefore the `values` vector for all dimensions must be the same (longer vectors will be truncated).

=item * valuessrc

Sets the source reference on plot.ly for  values .

=item * visible

Shows the dimension when set to `true` (the default). Hides the dimension for `false`.

=back

=head1 AUTHOR

Pablo Rodríguez González <pablo.rodriguez.gonzalez@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Pablo Rodríguez González.

This is free software, licensed under:

  The MIT (X11) License

=cut
