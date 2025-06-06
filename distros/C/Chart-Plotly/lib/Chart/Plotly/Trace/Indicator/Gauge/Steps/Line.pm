package Chart::Plotly::Trace::Indicator::Gauge::Steps::Line;
use Moose;
use MooseX::ExtraArgs;
use Moose::Util::TypeConstraints qw(enum union);
if ( !defined Moose::Util::TypeConstraints::find_type_constraint('PDL') ) {
    Moose::Util::TypeConstraints::type('PDL');
}

our $VERSION = '0.042';    # VERSION

# ABSTRACT: This attribute is one of the possible options for the trace indicator.

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

has color => ( is            => "rw",
               isa           => "Str",
               documentation => "Sets the color of the line enclosing each sector.",
);

has width => ( is            => "rw",
               isa           => "Num",
               documentation => "Sets the width (in px) of the line enclosing each sector.",
);

__PACKAGE__->meta->make_immutable();
1;

__END__

=pod

=encoding utf-8

=head1 NAME

Chart::Plotly::Trace::Indicator::Gauge::Steps::Line - This attribute is one of the possible options for the trace indicator.

=head1 VERSION

version 0.042

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

This attribute is part of the possible options for the trace indicator.

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

=head1 ATTRIBUTES

=over

=item * color

Sets the color of the line enclosing each sector.

=item * width

Sets the width (in px) of the line enclosing each sector.

=back

=head1 AUTHOR

Pablo Rodríguez González <pablo.rodriguez.gonzalez@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2022 by Pablo Rodríguez González.

This is free software, licensed under:

  The MIT (X11) License

=cut
