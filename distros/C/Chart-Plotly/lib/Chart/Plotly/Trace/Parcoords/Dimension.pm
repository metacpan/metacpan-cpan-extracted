package Chart::Plotly::Trace::Parcoords::Dimension;
use Moose;
use MooseX::ExtraArgs;
use Moose::Util::TypeConstraints qw(enum union);
if ( !defined Moose::Util::TypeConstraints::find_type_constraint('PDL') ) {
    Moose::Util::TypeConstraints::type('PDL');
}

our $VERSION = '0.027';    # VERSION

# ABSTRACT: This attribute is one of the possible options for the trace parcoords.

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

has constraintrange => (
    is  => "rw",
    isa => "ArrayRef|PDL",
    documentation =>
      "The domain range to which the filter on the dimension is constrained. Must be an array of `[fromValue, toValue]` with `fromValue <= toValue`, or if `multiselect` is not disabled, you may give an array of arrays, where each inner array is `[fromValue, toValue]`.",
);

has description => (
             is      => "ro",
             default => "The dimensions (variables) of the parallel coordinates chart. 2..60 dimensions are supported.",
);

has label => ( is            => "rw",
               isa           => "Str",
               documentation => "The shown name of the dimension.",
);

has multiselect => ( is            => "rw",
                     isa           => "Bool",
                     documentation => "Do we allow multiple selection ranges or just a single range?",
);

has name => (
    is  => "rw",
    isa => "Str",
    documentation =>
      "When used in a template, named items are created in the output figure in addition to any items the figure already has in this array. You can modify these items in the output figure by making your own item with `templateitemname` matching this `name` alongside your modifications (including `visible: false` or `enabled: false` to hide it). Has no effect outside of a template.",
);

has range => (
    is  => "rw",
    isa => "ArrayRef|PDL",
    documentation =>
      "The domain range that represents the full, shown axis extent. Defaults to the `values` extent. Must be an array of `[fromValue, toValue]` with finite numbers as elements.",
);

has templateitemname => (
    is  => "rw",
    isa => "Str",
    documentation =>
      "Used to refer to a named item in this array in the template. Named items from the template will be created even without a matching item in the input figure, but you can modify one by making an item with `templateitemname` matching its `name`, alongside your modifications (including `visible: false` or `enabled: false` to hide it). If there is no template or no matching item, this item will be hidden unless you explicitly show it with `visible: true`.",
);

has tickformat => (
    is  => "rw",
    isa => "Str",
    documentation =>
      "Sets the tick label formatting rule using d3 formatting mini-language which is similar to those of Python. See https://github.com/d3/d3-format/blob/master/README.md#locale_format",
);

has ticktext => ( is            => "rw",
                  isa           => "ArrayRef|PDL",
                  documentation => "Sets the text displayed at the ticks position via `tickvals`.",
);

has ticktextsrc => ( is            => "rw",
                     isa           => "Str",
                     documentation => "Sets the source reference on plot.ly for  ticktext .",
);

has tickvals => ( is            => "rw",
                  isa           => "ArrayRef|PDL",
                  documentation => "Sets the values at which ticks on this axis appear.",
);

has tickvalssrc => ( is            => "rw",
                     isa           => "Str",
                     documentation => "Sets the source reference on plot.ly for  tickvals .",
);

has values => (
    is  => "rw",
    isa => "ArrayRef|PDL",
    documentation =>
      "Dimension values. `values[n]` represents the value of the `n`th point in the dataset, therefore the `values` vector for all dimensions must be the same (longer vectors will be truncated). Each value must be a finite number.",
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

Chart::Plotly::Trace::Parcoords::Dimension - This attribute is one of the possible options for the trace parcoords.

=head1 VERSION

version 0.027

=head1 SYNOPSIS

 use Chart::Plotly qw(show_plot);
 use Chart::Plotly::Trace::Parcoords;
 # Example data from: https://plot.ly/javascript/parallel-coordinates-plot/#adding-dimensions
 my $parcoords = Chart::Plotly::Trace::Parcoords->new(
  line=> {
     color=> 'blue'
   },
   
   dimensions=> [{
     range=> [1, 5],
     constraintrange=> [1, 2],
     label=> 'A',
     values=> [1,4]
   }, {    
     range=> [1,5],
     label=> 'B',
     values=> [3,1.5],
     tickvals=> [1.5,3,4.5]
   }, {
     range=> [1, 5],
     label=> 'C',
     values=> [2,4],
     tickvals=> [1,2,4,5],
     ticktext=> ['text 1','text 2','text 4','text 5']
   }, {
     range=> [1, 5],
     label=> 'D',
     values=> [4,2]
   }]
 );
 
 show_plot([ $parcoords ]);

=head1 DESCRIPTION

This attribute is part of the possible options for the trace parcoords.

This file has been autogenerated from the official plotly.js source.

If you like Plotly, please support them: L<https://plot.ly/> 
Open source announcement: L<https://plot.ly/javascript/open-source-announcement/>

Full reference: L<https://plot.ly/javascript/reference/#parcoords>

=head1 DISCLAIMER

This is an unofficial Plotly Perl module. Currently I'm not affiliated in any way with Plotly. 
But I think plotly.js is a great library and I want to use it with perl.

=head1 METHODS

=head2 TO_JSON

Serialize the trace to JSON. This method should be called only by L<JSON> serializer.

=head1 ATTRIBUTES

=over

=item * constraintrange

The domain range to which the filter on the dimension is constrained. Must be an array of `[fromValue, toValue]` with `fromValue <= toValue`, or if `multiselect` is not disabled, you may give an array of arrays, where each inner array is `[fromValue, toValue]`.

=item * description

=item * label

The shown name of the dimension.

=item * multiselect

Do we allow multiple selection ranges or just a single range?

=item * name

When used in a template, named items are created in the output figure in addition to any items the figure already has in this array. You can modify these items in the output figure by making your own item with `templateitemname` matching this `name` alongside your modifications (including `visible: false` or `enabled: false` to hide it). Has no effect outside of a template.

=item * range

The domain range that represents the full, shown axis extent. Defaults to the `values` extent. Must be an array of `[fromValue, toValue]` with finite numbers as elements.

=item * templateitemname

Used to refer to a named item in this array in the template. Named items from the template will be created even without a matching item in the input figure, but you can modify one by making an item with `templateitemname` matching its `name`, alongside your modifications (including `visible: false` or `enabled: false` to hide it). If there is no template or no matching item, this item will be hidden unless you explicitly show it with `visible: true`.

=item * tickformat

Sets the tick label formatting rule using d3 formatting mini-language which is similar to those of Python. See https://github.com/d3/d3-format/blob/master/README.md#locale_format

=item * ticktext

Sets the text displayed at the ticks position via `tickvals`.

=item * ticktextsrc

Sets the source reference on plot.ly for  ticktext .

=item * tickvals

Sets the values at which ticks on this axis appear.

=item * tickvalssrc

Sets the source reference on plot.ly for  tickvals .

=item * values

Dimension values. `values[n]` represents the value of the `n`th point in the dataset, therefore the `values` vector for all dimensions must be the same (longer vectors will be truncated). Each value must be a finite number.

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
