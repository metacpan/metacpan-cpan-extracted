package Chart::Plotly::Trace::Indicator;
use Moose;
use MooseX::ExtraArgs;
use Moose::Util::TypeConstraints qw(enum union);
if ( !defined Moose::Util::TypeConstraints::find_type_constraint('PDL') ) {
    Moose::Util::TypeConstraints::type('PDL');
}

use Chart::Plotly::Trace::Indicator::Delta;
use Chart::Plotly::Trace::Indicator::Domain;
use Chart::Plotly::Trace::Indicator::Gauge;
use Chart::Plotly::Trace::Indicator::Number;
use Chart::Plotly::Trace::Indicator::Stream;
use Chart::Plotly::Trace::Indicator::Title;
use Chart::Plotly::Trace::Indicator::Transform;

our $VERSION = '0.035';    # VERSION

# ABSTRACT: An indicator is used to visualize a single `value` along with some contextual information such as `steps` or a `threshold`, using a combination of three visual elements: a number, a delta, and/or a gauge. Deltas are taken with respect to a `reference`. Gauges can be either angular or bullet (aka linear) gauges.

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
    my $plotly_meta = delete $hash{'pmeta'};
    if ( defined $plotly_meta ) {
        $hash{'meta'} = $plotly_meta;
    }
    %hash = ( %hash, %$extra_args );
    delete $hash{'extra_args'};
    if ( $self->can('type') && ( !defined $hash{'type'} ) ) {
        $hash{type} = $self->type();
    }
    return \%hash;
}

sub type {
    my @components = split( /::/, __PACKAGE__ );
    return lc( $components[-1] );
}

has align => (
    is  => "rw",
    isa => enum( [ "left", "center", "right" ] ),
    documentation =>
      "Sets the horizontal alignment of the `text` within the box. Note that this attribute has no effect if an angular gauge is displayed: in this case, it is always centered",
);

has customdata => (
    is  => "rw",
    isa => "ArrayRef|PDL",
    documentation =>
      "Assigns extra data each datum. This may be useful when listening to hover, click and selection events. Note that, *scatter* traces also appends customdata items in the markers DOM elements",
);

has customdatasrc => ( is            => "rw",
                       isa           => "Str",
                       documentation => "Sets the source reference on plot.ly for  customdata .",
);

has delta => ( is  => "rw",
               isa => "Maybe[HashRef]|Chart::Plotly::Trace::Indicator::Delta", );

has domain => ( is  => "rw",
                isa => "Maybe[HashRef]|Chart::Plotly::Trace::Indicator::Domain", );

has gauge => ( is  => "rw",
               isa => "Maybe[HashRef]|Chart::Plotly::Trace::Indicator::Gauge", );

has ids => (
    is  => "rw",
    isa => "ArrayRef|PDL",
    documentation =>
      "Assigns id labels to each datum. These ids for object constancy of data points during animation. Should be an array of strings, not numbers or any other type.",
);

has idssrc => ( is            => "rw",
                isa           => "Str",
                documentation => "Sets the source reference on plot.ly for  ids .",
);

has pmeta => (
    is  => "rw",
    isa => "Any|ArrayRef[Any]",
    documentation =>
      "Assigns extra meta information associated with this trace that can be used in various text attributes. Attributes such as trace `name`, graph, axis and colorbar `title.text`, annotation `text` `rangeselector`, `updatemenues` and `sliders` `label` text all support `meta`. To access the trace `meta` values in an attribute in the same trace, simply use `%{meta[i]}` where `i` is the index or key of the `meta` item in question. To access trace `meta` in layout attributes, use `%{data[n[.meta[i]}` where `i` is the index or key of the `meta` and `n` is the trace index.",
);

has metasrc => ( is            => "rw",
                 isa           => "Str",
                 documentation => "Sets the source reference on plot.ly for  meta .",
);

has mode => (
    is  => "rw",
    isa => "Str",
    documentation =>
      "Determines how the value is displayed on the graph. `number` displays the value numerically in text. `delta` displays the difference to a reference value in text. Finally, `gauge` displays the value graphically on an axis.",
);

has name => ( is            => "rw",
              isa           => "Str",
              documentation => "Sets the trace name. The trace name appear as the legend item and on hover.",
);

has number => ( is  => "rw",
                isa => "Maybe[HashRef]|Chart::Plotly::Trace::Indicator::Number", );

has stream => ( is  => "rw",
                isa => "Maybe[HashRef]|Chart::Plotly::Trace::Indicator::Stream", );

has title => ( is  => "rw",
               isa => "Maybe[HashRef]|Chart::Plotly::Trace::Indicator::Title", );

has transforms => ( is  => "rw",
                    isa => "ArrayRef|ArrayRef[Chart::Plotly::Trace::Indicator::Transform]", );

has uid => (
    is  => "rw",
    isa => "Str",
    documentation =>
      "Assign an id to this trace, Use this to provide object constancy between traces during animations and transitions.",
);

has uirevision => (
    is  => "rw",
    isa => "Any",
    documentation =>
      "Controls persistence of some user-driven changes to the trace: `constraintrange` in `parcoords` traces, as well as some `editable: true` modifications such as `name` and `colorbar.title`. Defaults to `layout.uirevision`. Note that other user-driven trace attribute changes are controlled by `layout` attributes: `trace.visible` is controlled by `layout.legend.uirevision`, `selectedpoints` is controlled by `layout.selectionrevision`, and `colorbar.(x|y)` (accessible with `config: {editable: true}`) is controlled by `layout.editrevision`. Trace changes are tracked by `uid`, which only falls back on trace index if no `uid` is provided. So if your app can add/remove traces before the end of the `data` array, such that the same trace has a different index, you can still preserve user-driven changes if you give each trace a `uid` that stays with it as it moves.",
);

has value => ( is            => "rw",
               isa           => "Num",
               documentation => "Sets the number to be displayed.",
);

has visible => (
    is => "rw",
    documentation =>
      "Determines whether or not this trace is visible. If *legendonly*, the trace is not drawn, but can appear as a legend item (provided that the legend itself is visible).",
);

__PACKAGE__->meta->make_immutable();
1;

__END__

=pod

=encoding utf-8

=head1 NAME

Chart::Plotly::Trace::Indicator - An indicator is used to visualize a single `value` along with some contextual information such as `steps` or a `threshold`, using a combination of three visual elements: a number, a delta, and/or a gauge. Deltas are taken with respect to a `reference`. Gauges can be either angular or bullet (aka linear) gauges.

=head1 VERSION

version 0.035

=head1 SYNOPSIS

 use Chart::Plotly;
 use Chart::Plotly::Plot;
 use JSON;
 use Chart::Plotly::Trace::Indicator;
 
 # Example from https://github.com/plotly/plotly.js/blob/68c2aefa8ab6af09c598b3739149e2d5e89155d9/test/image/mocks/indicator_grid_template.json
 my $trace1 = Chart::Plotly::Trace::Indicator->new({'domain' => {'column' => 0, 'row' => 0, }, 'gauge' => {'axis' => {'range' => [0, 200, ], 'visible' => JSON::false, }, }, 'delta' => {'reference' => 60, }, 'value' => 120, });
 
 my $trace2 = Chart::Plotly::Trace::Indicator->new({'value' => 120, 'gauge' => {'axis' => {'visible' => JSON::false, 'range' => [-200, 200, ], }, 'shape' => 'bullet', }, 'domain' => {'y' => [0.15, 0.35, ], 'x' => [0.05, 0.5, ], }, });
 
 my $trace3 = Chart::Plotly::Trace::Indicator->new({'domain' => {'column' => 1, 'row' => 0, }, 'value' => 120, 'mode' => 'number+delta', });
 
 my $trace4 = Chart::Plotly::Trace::Indicator->new({'domain' => {'row' => 1, 'column' => 1, }, 'value' => 40, 'mode' => 'delta', });
 
 
 my $plot = Chart::Plotly::Plot->new(
     traces => [$trace1, $trace2, $trace3, $trace4, ],
     layout => 
         {'margin' => {'b' => 25, 'l' => 25, 'r' => 25, 't' => 25, }, 'template' => {'data' => {'indicator' => [{'mode' => 'number+delta+gauge', 'title' => {'text' => 'Title', }, 'delta' => {'reference' => 60, }, }, ], }, }, 'height' => 400, 'grid' => {'columns' => 2, 'pattern' => 'independent', 'rows' => 2, }, 'width' => 700, }
 ); 
 
 Chart::Plotly::show_plot($plot);

=head1 DESCRIPTION

An indicator is used to visualize a single `value` along with some contextual information such as `steps` or a `threshold`, using a combination of three visual elements: a number, a delta, and/or a gauge. Deltas are taken with respect to a `reference`. Gauges can be either angular or bullet (aka linear) gauges.

Screenshot of the above example:

=for HTML <p>
<img src="https://raw.githubusercontent.com/pablrod/p5-Chart-Plotly/master/examples/traces/indicator.png" alt="Screenshot of the above example">
</p>

=for markdown ![Screenshot of the above example](https://raw.githubusercontent.com/pablrod/p5-Chart-Plotly/master/examples/traces/indicator.png)

=for HTML <p>
<iframe src="https://raw.githubusercontent.com/pablrod/p5-Chart-Plotly/master/examples/traces/indicator.html" style="border:none;" width="80%" height="520"></iframe>
</p>

This file has been autogenerated from the official plotly.js source.

If you like Plotly, please support them: L<https://plot.ly/> 
Open source announcement: L<https://plot.ly/javascript/open-source-announcement/>

Full reference: L<https://plot.ly/javascript/reference/#indicator>

=head1 DISCLAIMER

This is an unofficial Plotly Perl module. Currently I'm not affiliated in any way with Plotly. 
But I think plotly.js is a great library and I want to use it with perl.

=head1 METHODS

=head2 TO_JSON

Serialize the trace to JSON. This method should be called only by L<JSON> serializer.

=head2 type

Trace type.

=head1 ATTRIBUTES

=over

=item * align

Sets the horizontal alignment of the `text` within the box. Note that this attribute has no effect if an angular gauge is displayed: in this case, it is always centered

=item * customdata

Assigns extra data each datum. This may be useful when listening to hover, click and selection events. Note that, *scatter* traces also appends customdata items in the markers DOM elements

=item * customdatasrc

Sets the source reference on plot.ly for  customdata .

=item * delta

=item * domain

=item * gauge

=item * ids

Assigns id labels to each datum. These ids for object constancy of data points during animation. Should be an array of strings, not numbers or any other type.

=item * idssrc

Sets the source reference on plot.ly for  ids .

=item * pmeta

Assigns extra meta information associated with this trace that can be used in various text attributes. Attributes such as trace `name`, graph, axis and colorbar `title.text`, annotation `text` `rangeselector`, `updatemenues` and `sliders` `label` text all support `meta`. To access the trace `meta` values in an attribute in the same trace, simply use `%{meta[i]}` where `i` is the index or key of the `meta` item in question. To access trace `meta` in layout attributes, use `%{data[n[.meta[i]}` where `i` is the index or key of the `meta` and `n` is the trace index.

=item * metasrc

Sets the source reference on plot.ly for  meta .

=item * mode

Determines how the value is displayed on the graph. `number` displays the value numerically in text. `delta` displays the difference to a reference value in text. Finally, `gauge` displays the value graphically on an axis.

=item * name

Sets the trace name. The trace name appear as the legend item and on hover.

=item * number

=item * stream

=item * title

=item * transforms

=item * uid

Assign an id to this trace, Use this to provide object constancy between traces during animations and transitions.

=item * uirevision

Controls persistence of some user-driven changes to the trace: `constraintrange` in `parcoords` traces, as well as some `editable: true` modifications such as `name` and `colorbar.title`. Defaults to `layout.uirevision`. Note that other user-driven trace attribute changes are controlled by `layout` attributes: `trace.visible` is controlled by `layout.legend.uirevision`, `selectedpoints` is controlled by `layout.selectionrevision`, and `colorbar.(x|y)` (accessible with `config: {editable: true}`) is controlled by `layout.editrevision`. Trace changes are tracked by `uid`, which only falls back on trace index if no `uid` is provided. So if your app can add/remove traces before the end of the `data` array, such that the same trace has a different index, you can still preserve user-driven changes if you give each trace a `uid` that stays with it as it moves.

=item * value

Sets the number to be displayed.

=item * visible

Determines whether or not this trace is visible. If *legendonly*, the trace is not drawn, but can appear as a legend item (provided that the legend itself is visible).

=back

=head1 AUTHOR

Pablo Rodríguez González <pablo.rodriguez.gonzalez@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Pablo Rodríguez González.

This is free software, licensed under:

  The MIT (X11) License

=cut
