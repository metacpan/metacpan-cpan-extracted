package Chart::GGPlot::Layer;

# ABSTRACT: Chart::GGPlot layer

use Chart::GGPlot::Class qw(:pdl);
use namespace::autoclean;

our $VERSION = '0.002002'; # VERSION

use List::AllUtils qw(pairgrep pairkeys pairmap);
use Module::Load;
use Data::Frame::Types qw(DataFrame);
use Data::Frame::Util qw(is_discrete);
use Types::Standard qw(Bool Defined Enum HashRef InstanceOf Maybe);

use Chart::GGPlot::Types qw(:all);
use Chart::GGPlot::Aes;
use Chart::GGPlot::Stat::Functions qw(:all);
use Chart::GGPlot::Util qw(:all);


has data => (
    is  => 'ro',
    isa => Maybe [DataFrame],
);
has mapping => (
    is     => 'rw',
    coerce => 1,
    isa    => GGParams,
);
has geom        => ( is => 'ro', required => 1 );
has geom_params => (
    is     => 'rw',
    isa    => GGParams,
    coerce => 1,
);
has stat        => ( is => 'ro', required => 1 );
has stat_params => (
    is     => 'rw',
    isa    => GGParams,
    coerce => 1,
);
has aes_params => (
    is     => 'rw',
    isa    => AesMapping,
    coerce => 1,
);
has position    => ( is => 'ro', required => 1 );
has inherit_aes => ( is => 'ro', default  => sub { false } );


has show_legend => ( is => 'ro' );

around BUILDARGS( $orig, $class : @rest ) {
    my %params = @rest;
    return $class->$orig( %{ $class->_layer(%params) } );
};

classmethod _find_subclass ($super, $name) {
    return (
          $name =~ /^Chart::GGPlot::/
        ? $name
        : "Chart::GGPlot::${super}::"
          . join( '', map { ucfirst($_) } split( /_/, $name ) )
    );
}

classmethod _layer (Defined :$geom, Defined :$stat,
                    :$data = undef, :$mapping = undef,
                    Defined :$position,
                    :$params = { na_rm => false },
                    :$inherit_aes = true, :$check_aes = true,
                    :$check_param = true, :$show_legend = NA
  ) {
    $mapping //= Chart::GGPlot::Aes->new();
    unless ( defined $params->at("na_rm") ) {
        $params->set( "na_rm", "nan" );
    }

    my $find_subclass = fun( $super, $x ) {
        unless ( Ref::Util::is_ref($x) ) {  # $x is a class name
            my $subclass = $class->_find_subclass( $super, $x );
            load $subclass;
            return $subclass->new();
        }
        return $x;
    };
    $geom     = $find_subclass->( 'Geom',     $geom );
    $stat     = $find_subclass->( 'Stat',     $stat );
    $position = $find_subclass->( 'Position', $position );

    # Split up params between aesthetics, geom, and stat
    $params = Chart::GGPlot::Aes->new( $params->flatten );
    my $select_params = sub {
        my $names = shift;
        my %selected =
          map { $params->exists($_) ? ( $_ => $params->at($_) ) : () } @$names;
        return \%selected;
    };
    my $aes_params  = $geom ? &$select_params( $geom->aesthetics )       : {};
    my $geom_params = $geom ? &$select_params( $geom->parameters(true) ) : {};
    my $stat_params = $stat ? &$select_params( $stat->parameters(true) ) : {};

    # Warn about extra params and aesthetics

    my $all = [ $aes_params, $geom_params, $stat_params ]
      ->map( sub { $_->keys->flatten } );
    my $extra_param = $params->keys->setdiff($all);
    if ( $check_param and not $extra_param->isempty ) {
        carp( "Ignoring unknown parameters: " . join( ", ", @$extra_param ) );
    }

    my %seen_aes =
      map { $_ => 1 } ( @{ $geom->aesthetics }, @{ $stat->aesthetics } );
    my @extra_aes =
      grep { !exists $seen_aes{$_} }
      grep { defined $mapping->at($_) } @{ $mapping->keys };

    if ( $check_aes and @extra_aes ) {
        carp( "Ignoring unknown aesthetics: " . join( ", ", @extra_aes ) );
    }

    return {
        geom        => $geom,
        stat        => $stat,
        data        => $data,
        mapping     => $mapping,
        position    => $position,
        inherit_aes => $inherit_aes,
        show_legend => $show_legend,
        geom_params => $geom_params,
        stat_params => $stat_params,
        aes_params  => $aes_params,
    };
}


method string () {
    my $s = '';
    if ( $self->mapping ) {
        $s .= sprintf( "mapping: %s\n", clist( $self->mapping ) );
    }
    $s .=
      sprintf( "%s: %s\n", ref( $self->geom ), clist( $self->geom_params ) );
    $s .=
      sprintf( "%s: %s\n", ref( $self->stat ), clist( $self->stat_params ) );
    $s .= sprintf( "%s\n", ref( $self->position ) );
    return $s;
}

method layer_data ($plot_data) {
    return $plot_data unless ( defined $self->data );

    my $data = call_if_coderef( $self->data, $plot_data );
    unless ( $data->$_DOES('Data::Frame') ) {
        die("Data function must return a dataframe object");
    }
    return $data;
}

method compute_aesthetics ( $data, $plot ) {
    my $aesthetics =
        $self->inherit_aes
      ? $self->mapping->defaults( $plot->mapping )
      : $self->mapping;

    # Drop aesthetics that are set or calculated
    my $set        = $aesthetics->keys->intersect( $self->aes_params->keys );
    my $calculated = $self->calculated_aes($aesthetics);

    # !set and !calculated
    $aesthetics = $aesthetics->hslice(
        $aesthetics->keys->setdiff( $set->union($calculated) ) );

    # Override grouping if set in layer
    if ( $self->geom_params->exists('group') ) {
        $aesthetics->set( 'group', $self->aes_params->at('group') );
    }

    $plot->scales->add_defaults( $data, $aesthetics );

    # Evaluate and check aesthetics
    my $evaled = Data::Frame->new( columns =>
          [ pairmap { $a => $data->eval_tidy($b) } ( $aesthetics->flatten ) ] );

    # If there is no data, look at longest evaluated aesthetic.
    my $n =
         $data->nrow
      || $evaled->nrow
      || List::AllUtils::max(
        @{ $evaled->names->map( sub { $evaled->at($_)->length } ) } );
    Chart::GGPlot::Aes->check_aesthetics( $evaled, $n );

    # Set special group and panel vars
    $evaled->set( 'PANEL', ( $data->isempty and $n > 0 )
        ? pdl(0)
        : $data->at('PANEL') );
    $evaled = $self->add_group($evaled);

    return $evaled;
}

method compute_statistic ( $data, $layout ) {
    return Data::Frame->new() if ( $data->isempty );

    my $params = $self->stat->setup_params( $data, $self->stat_params );
    my $data   = $self->stat->setup_data( $data, $params );
    return $self->stat->compute_layer( $data, $params, $layout );
}

method map_statistic ( $data, $plot ) {
    return Data::Frame->new() if ( $data->isempty );

    # Assemble aesthetics from layer, plot and stat mappings
    my $aesthetics = $self->mapping;
    if ( $self->inherit_aes ) {
        $aesthetics = $aesthetics->defaults( $plot->mapping );
    }

    $aesthetics = $aesthetics->defaults( $self->stat->default_aes );
    #$aesthetics = compact($aesthetics);

    my $new = $aesthetics->hslice( $self->calculated_aes($aesthetics) );
    return $data if ( $new->isempty );

    my $stat_data =
      Data::Frame->new(
        columns => [ pairmap { $a => $data->eval_tidy($b) } $new->flatten ] );
    $plot->scales->add_defaults( $data, $new );

    # Transform the values, if the scale say it's ok
    if ( $self->stat->retransform ) {
        $stat_data = $plot->scales->transform_df($stat_data);
    }

    return $data->merge($stat_data);
}

method compute_geom_1($data) {
    return Data::Frame->new() if ( $data->isempty );

    $self->geom->check_required_aes(
        [ @{ $data->names }, @{ $self->aes_params->names } ] );

    my $geom_params = $self->geom_params->merge( $self->aes_params );
    $self->validate_params($geom_params);
    return $self->geom->setup_data( $data, $geom_params );
}

method compute_position ( $data, $layout ) {
    return Data::Frame->new() if ( $data->isempty );

    my $params = $self->position->setup_params($data);
    $data = $self->position->setup_data( $data, $params );
    return $self->position->compute_layer( $data, $params, $layout );
}

# Combine aesthetics, defaults, and params
method compute_geom_2 ($data) {
    return Data::Frame->new() if ( $data->isempty );
    return $self->geom->use_defaults( $data, $self->aes_params );
}

method finish_statistics ($data) {
    $self->stat->finish_layer( $data, $self->stat_params );
}

# return an arrayref of keys.
method calculated_aes ($aesthetics) {
    # TODO: better to use PPR to make sure the function is "stat"?
    return [
        pairkeys(
            pairgrep {
                $b->$_DOES('Eval::Quosure') and $b->expr =~ /^\s*stat\s*\(/;
            }
            $aesthetics->flatten
        )
    ];
}

classmethod add_group ($data) {
    return $data if $data->isempty;

    if ( $data->exists('group') ) {
        my $group = $data->at('group');
        $data->set( 'group', $group->id );
        $data->set( 'group_raw', $group );
    }
    else {
        my $discrete_columns = $data->names->grep(
            sub {
                $_ ne 'label'
                  and $_ ne 'PANEL'
                  and is_discrete( $data->at($_) );
            }
        );
        if ( $discrete_columns->length ) {
            $data->set( 'group', $data->select_columns($discrete_columns)->id );
        }
        else {
            $data->set( 'group', pdl(0) );
        }
    }
    return $data;
}

# For type validation on aes and params
my $aes2type = {
    hjust => HJust,
    vjust => VJust,
};

classmethod validate_params($params) {
    for my $k ( @{ $params->keys } ) {
        my $type = $aes2type->{$k};
        next unless $type;
        my $val = $params->at($k);
        if ( my $msg = $type->validate($val) ) {
            die "Validation failed on parameter \"$k\": $msg";
        }
    }
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Chart::GGPlot::Layer - Chart::GGPlot layer

=head1 VERSION

version 0.002002

=head1 DESCRIPTION

A layer is a combination of data, stat and geom with a potential position
adjustment. Usually layers are created using C<geom_*> or C<stat_*>
calls but it can also be created directly using this class.

=head1 ATTRIBUTES

=head2 data

The data to be displayed in this layer.
If C<undef>, the default, the data is inherited from the plot data as
specified in the call to C<ggplot()>.

=head2 mapping

Set of aesthetic mappings created by C<aes()>.
If specified and C<inherit_aes> is true (the default), it's combined with
the default mapping at the top level of the plot.
You must supply this attribute if there no plot mapping.

=head2 geom

The geometric object to use display the data.

=head2 stat

The statistical transformation to use on the data for this layer, as a
string.

=head2 position

Position adjustment, either as a string, or the result of a call to a
position adjust function.

=head2 inherit_aes

If false, overrides the default aesthetics, rather than combining with them.
This is most useful for helper functions that define both data and
aesthetics and shouldn't inherit behaviour from the default plot
specification.

=head2 params

Additional parameters to the "geom" and "stat".

=head2 show_legend

Should this layer be included in the legends?

=over 4

=item *

C<undef>, includes if any aesthetics are mapped.

=item *

A defined true scalar (non-Chart::GGPlot::Aes), never includes.

=item *

A defined false scalar (non-Chart::GGPlot::Aes), always includes. 

=item *

A L<Chart::GGPlot::Aes> object whose values are booleans, to finely

select the aesthetics to display.

=back

=head1 METHODS

=head2 string()

=head1 AUTHOR

Stephan Loyd <sloyd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019-2023 by Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
