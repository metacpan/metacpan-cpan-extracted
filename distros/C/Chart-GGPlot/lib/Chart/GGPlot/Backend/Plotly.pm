package Chart::GGPlot::Backend::Plotly;

# ABSTRACT: Plotly backend for Chart::GGPlot

use Chart::GGPlot::Class qw(:pdl);
use namespace::autoclean;

our $VERSION = '0.0005'; # VERSION

with qw(Chart::GGPlot::Backend);

use Chart::Plotly 0.025 qw(show_plot);
use Chart::Plotly::Plot;
use Chart::Plotly::Image::Orca;

use Data::Munge qw(elem);
use JSON;
use List::AllUtils qw(pairmap pairwise uniq);
use Module::Load;
use Types::Standard qw(HashRef Int);

use Chart::GGPlot::Aes;
use Chart::GGPlot::Util qw(:all);
use Chart::GGPlot::Backend::Plotly::Geom;
use Chart::GGPlot::Backend::Plotly::Util qw(br to_rgb);
use Chart::GGPlot::Util qw(rescale);

#TODO: To test and see which value is proper.
our $WEBGL_THRESHOLD = 2000;

classmethod _split_on($class_geom_impl, $data) {
    my $aes = $class_geom_impl->split_on;
    return [ grep { $data->exists($_) } map { "${_}_raw" } @$aes ];
}

method layer_to_traces ($layer, $data, $prestats_data, $layout, $plot) {
    return if ( $data->isempty );

    my $geom            = $layer->geom;
    my $class_geom      = ( ref($geom) || $geom );
    my $short           = $class_geom =~ s/^Chart::GGPlot::Geom:://r;
    my $class_geom_impl = "Chart::GGPlot::Backend::Plotly::Geom::$short";
    load($class_geom_impl);

    my $geom_params = $layer->geom_params;
    my $stat_params = $layer->stat_params;
    my $aes_params  = $layer->aes_params;
    my $params = $geom_params->merge($stat_params)->merge($aes_params);

    my $coord  = $layout->coord;

    my %discrete_scales = map {
        my $scale = $_;
        if ( $scale->isa('Chart::GGPlot::Scale::Discrete') ) {
            map { $_ => $scale } @{ $scale->aesthetics };
        }
        else {
            ();
        }
    } @{ $plot->scales->non_position_scales->scales };

    # variables that produce multiple traces and deserve their own legend entries
    my @split_legend = map { "${_}_raw" } ( sort keys %discrete_scales );
    $log->debugf( "Variables that would cause legend be splitted : %s",
        Dumper( \@split_legend ) )
      if $log->is_debug;

    my $split_by =
      [ uniq( @split_legend, @{ $self->_split_on( $class_geom_impl, $data ) } )
      ];

    my $split_vars = $split_by->intersect($data->names);

    my $hover_text_aes;     # which aes shall be displayed in hover text?
    {
        # While $plot->labels also looks like containing what we need,
        # actually it be cleared or set to other values, so it can't
        # really be used for generating the hovertext. Here we would
        # get the aes from $layer->mapping and $layer->stat.
        my $map      = $layer->mapping;
        my $calc_aes = $layer->stat->default_aes->hslice(
            $layer->calculated_aes( $layer->stat->default_aes ) );
        $map = $map->merge($calc_aes);
        if ( $layer->inherit_aes ) {
            $map = $map->merge( $plot->mapping );
        }
        $hover_text_aes = Chart::GGPlot::Plot->make_labels($map);
    }

    # put x and y at first in plotly hover text
    my $all_aesthetics = Chart::GGPlot::Aes->all_aesthetics;
    my @hover_aes_ordered = (
        qw(x y),
        (
            sort grep {
                $_ ne 'x' and $_ ne 'y' and elem( $_, $all_aesthetics )
            } @{$hover_text_aes->keys}
        )
    );
    # throw out positional coordinates if we're hovering on fill
    my $hover_on = $class_geom_impl->hover_on();
    if ($hover_on eq 'fills') {
        @hover_aes_ordered =
          grep { not elem( $_, [qw(x xmin xmax y ymin ymax)] ) }
          @hover_aes_ordered;
    }
    my @hover_labels = map { $_ => $hover_text_aes->at($_) } @hover_aes_ordered;

    my $panel_to_traces = fun( $d, $panel_params ) {
        my $hovertext = $class_geom_impl->make_hovertext($d, \@hover_labels);
        $d->set( 'hovertext', PDL::SV->new($hovertext) );

        my @splitted_sorted;
        if ( $split_vars->length ) {
            my $fac = do {
                my $d_tmp      = $d->select_columns($split_vars);
                my $lvls       = $d_tmp->uniq->sort($split_vars);
                my $fac_levels = $lvls->id;
                my $i          = 0;
                my %fac_levels = map { $_ => $i++ } $fac_levels->flatten;
                PDL::Factor->new(
                    [ map { $fac_levels{$_} } $d_tmp->id->flatten ],
                    levels  => [ 0 .. $fac_levels->length - 1 ],
                );
            };

            my $splitted = $d->split($fac);
            @splitted_sorted =
              map { $splitted->{$_} } sort { $a cmp $b } keys %$splitted;
        }
        else {
            push @splitted_sorted, $d;
        }

        my $showlegend = @split_legend->intersect( $data->names )->length > 0;
        return @splitted_sorted->map(
            sub {
                my ($d) = @_;

                my $traces = $class_geom_impl->to_traces($d, $params, $plot);
                for my $trace (@$traces) {
                    my $legend_key = join(
                        ', ',
                        map {
                            if ( $d->exists($_) ) {
                                my $col_data = $d->at($_);
                                $col_data->slice(pdl(0))->as_pdlsv->at(0);
                            }
                            else {
                                ();
                            }
                        } @split_legend
                    );
                    $trace->name($legend_key);

                    # some types like heatmap may not have below methods
                    if ( $trace->can('showlegend') ) {
                        $trace->legendgroup($legend_key);
                        $trace->showlegend($showlegend);
                    }
                }
                return @$traces;
            }
        );
    };

    my $splitted_data = $data->split( $data->at('PANEL') );
    my $splitted_prestats_data =
      $prestats_data->split( $prestats_data->at('PANEL') );
    return [
        pairmap {
            my ( $panel_id, $panel_data ) = ( $a, $b );

            my $panel_prestats_data = $splitted_prestats_data->{$panel_id};
            my $traces = $panel_to_traces->(
                $class_geom_impl->prepare_data(
                    $panel_data, $panel_prestats_data, $layout,
                    $params,     $plot
                ),
                $layout->panel_params->at($panel_id)
            );
        }
        %$splitted_data
    ];
}


# create a hidden trace only for displaying colorbar
method _colorbar_to_trace ($guide) {
    load Chart::Plotly::Trace::Scatter;
    load Chart::Plotly::Trace::Scatter::Marker;
    load Chart::Plotly::Trace::Scatter::Marker::Colorbar;
    load Chart::Plotly::Trace::Scatter::Marker::Colorbar::Title;

    # do everything on a 0-1 scale

    my $rng = pdl($guide->bar->at('value')->minmax);
    my @colorscale_color = to_rgb( $guide->bar->at('color') )->list;
    my @colorscale_value =
      rescale( $guide->bar->at('value'), pdl( [ 0, 1 ] ), $rng )->list;
    my @colorscale = (
        pairwise { [ $a, $b ] }
        @colorscale_value, @colorscale_color
    );
    my $ticktext = $guide->key->at('label')->unpdl;
    my $tickvals =
      rescale( $guide->key->at('value'), pdl( [ 0, 1 ] ), $rng )->unpdl;

    my $marker = Chart::Plotly::Trace::Scatter::Marker->new(
        color      => [ 0, 1 ],
        colorscale => \@colorscale,
        colorbar   => Chart::Plotly::Trace::Scatter::Marker::Colorbar->new(
            title =>
              Chart::Plotly::Trace::Scatter::Marker::Colorbar::Title->new(
                text => $guide->title,
                side => 'top'
              ),
            # R's default is 1.2 "lines" for "legend.key.size".
            # We don't support the grid unit system now (maybe in future
            # we can develop it on Graphics::Grid::Unit), now we just
            # leave it be for plotly to use its default.
            #thickness => 30,
            tickmode => 'array',
            ticktext => $ticktext,
            tickvals => $tickvals,
            ticklen  => 2,
            len      => 0.5,
        ),
    );

    return Chart::Plotly::Trace::Scatter->new(
        x          => [0],
        y          => [0],
        type       => 'scatter',
        mode       => 'markers',
        opacity    => 0,
        hoverinfo  => 'none',
        showlegend => 0,
        marker     => $marker,
    );
}

method _to_plotly ($plot_built) {
    my $plot   = $plot_built->plot;
    my $layers = $plot->layers;
    my $layout = $plot_built->layout;

    my $plotly = Chart::Plotly::Plot->new();

    my $scales       = $layout->get_scales(0);
    my $panel_params = $layout->panel_params->at(0);

    # prepare theme and calc elements
    my $theme  = $plot->theme;
    my $elements = $theme->keys;
    for my $elname (@$elements) {
        my $el = $theme->at($elname);
        if ($el->$_DOES('Chart::GGPlot::Theme::Element')) {
            $theme->set($elname, $theme->calc_element($elname));
        }
    }

    my $el_panel_bg = $theme->at('panel_background');
    my $el_plot_bg  = $theme->at('plot_background');

    my %plotly_layout = (
        (
              ( not defined $el_panel_bg or $el_panel_bg->is_blank ) ? ()
            : ( plot_bgcolor => to_rgb( $el_panel_bg->at('fill') ) )
        ),
        (
              ( not defined $el_plot_bg or $el_plot_bg->is_blank ) ? ()
            : ( paper_bgcolor => to_rgb( $el_plot_bg->at('fill') ) )
        ),
    );

    my $labels        = $plot->labels;
    my $title = $labels->{title};
    if ( defined $labels->{title} and length($title) ) {

        # NOTE: plotly does not directly support subtitle
        #  See https://github.com/plotly/plotly.js/issues/233

        my $subtitle = $labels->{subtitle};
        if ( defined $subtitle and length($subtitle) ) {
            $title .= br() . sprintf( "%s", $subtitle );
        }
        $plotly_layout{title} = $title;
    }

    my $barmode;
    for my $xy (qw(x y)) {

        my $theme_el = sub {
            my ($elname) = @_;
            return ($theme->at("${elname}.${xy}") // $theme->at($elname));
        };

        my $axis_name;
        my $sc;
        if ( $plot->coordinates->DOES('Chart::GGPlot::Coord::Flip') ) {
            my $new_xy = $xy eq 'x' ? 'y' : 'x';
            $axis_name = "${new_xy}axis";
            $sc = $scales->{$new_xy};
        } else {
            $axis_name = "${xy}axis";
            $sc = $scales->{$xy};
        }

        my $axis_title = $sc->name // $labels->at($xy) // '';

        my $range = $panel_params->{"$xy.range"}->unpdl;
        my $labels = $panel_params->{"$xy.labels"}->as_pdlsv;

        # TODO: fix this in Data::Frame's PDL patch
        unless ( $labels->DOES('PDL::SV') and $labels->type >= PDL::float ) {
            $labels = PDL::SV->new(
                [
                    map {
                        my $s = sprintf( $PDL::doubleformat, $_ );
                        $s =~ s/^\s*//gr;
                    } @{ $labels->unpdl }
                ]
            );
        }
        $labels = $labels->unpdl;

        my $major_source = $panel_params->{"$xy.major_source"}->unpdl;
        my %ticks = pairwise { $a => $b } @$major_source, @$labels;

        # TODO:
        # Plotly does not well support minor ticks. Although we could
        # specify empty string at ticktext for minor ticks (like via below
        # lines I comment out), because of plotly's limitation minor
        # and major ticks has to be of same tick length on axises, which
        # looks ugly. In contrast ggplot2 would defaultly have a zero 
        # length for minor ticks. R's plotly module simply discards minor
        # ticks. For now we just follow that.

        # There is not necessarily minor ticks for an axis.
        #my $minor_source = $panel_params->{"$xy.minor_source"};
        #my $tickvals =
        #  defined $minor_source ? $minor_source->unpdl : $major_source;

        my $tickvals = $major_source;
        my $ticktext = [ map { $ticks{$_} // '' } @$tickvals ];

        my ( $el_axis_line, $el_axis_text, $el_axis_ticks, $el_axis_title ) =
          map { $theme_el->($_) } qw(axis_line axis_text axis_ticks axis_title);
        my $el_panel_grid = $theme_el->('panel_grid_major')
          // $theme->at('panel_grid');

        $plotly_layout{$axis_name} = {
            range     => $range,
            zeroline  => JSON::false,
            autorange => JSON::false,

            (
                  ( not defined $el_axis_title or $el_axis_title->is_blank )
                ? ()
                : ( title => $axis_title, )
            ),
            (
                  ( not defined $el_axis_ticks or $el_axis_ticks->is_blank )
                ? ()
                : (
                    ticks     => 'outside',
                    ticktext  => $ticktext,
                    tickvals  => $tickvals,
                    tickcolor => to_rgb( $el_axis_ticks->at('color') ),
                    tickangle => -( $el_axis_ticks->at('angle') // 0 ),
                )
            ),

            #ticklen => $theme->axis_ticks_length;
            #tickwidth => $el_axis_ticks,
            (
                  ( not defined $el_axis_text or $el_axis_text->is_blank )
                ? ( showticklabels => JSON::false, )
                : ( showticklabels => JSON::true, )
            ),
            (
                ( not defined $el_axis_line or $el_axis_line->is_blank ) ? ()
                : (
                    linecolor => to_rgb( $el_axis_line->at('color') ),
                    linewidth => 1,
                )
            ),
            (
                (
                    not defined $el_panel_grid
                      or $el_panel_grid->is_blank
                ) ? ( showgrid => JSON::false, )
                : (
                    gridcolor => to_rgb( $el_panel_grid->at('color') ),

                    # FIXME: fix this and use cex_to_px()
                    gridwidth => $el_panel_grid->at('size'),
                )
            ),
        };

        if ( $sc->isa('Chart::GGPlot::Scale::DiscretePosition') ) {
            my $has_dodge = List::AllUtils::any {
                $_->isa('Chart::GGPlot::Position::Dodge')
            } $layers->map( sub { $_->position } )->flatten;
            if ($has_dodge) {
                $barmode = 'dodge';
            }
        }
    } # for (qw(x y))

    # guides
    my $gdefs = $plot->guides->build(
        $plot->scales,
        labels          => $plot->labels,
        layers          => $layers,
        default_mapping => $plot->mapping
    );

    # if $gdefs is empty, then no legend is displayed.
    my $global_showlegend = !!@$gdefs;

    my %seen_legendgroup;
    for my $i ( 0 .. $#$layers ) {
        my $layer = $layers->[$i];
        my $data  = $plot_built->layer_data($i);
        my $prestats_data  = $plot_built->layer_prestats_data($i);

        $log->debug( "data at layer $i:\n" . $data->string ) if $log->is_debug;

        my $traces =
          $self->layer_to_traces( $layer, $data, $prestats_data,
            $layout, $plot );

        for my $panel (@$traces) {
            for my $trace (@$panel) {
                if ( $trace->can('showlegend') ) {
                    if ( not $global_showlegend ) {
                        $trace->showlegend(0);
                    }
                    elsif ( $seen_legendgroup{ $trace->legendgroup }++ ) {

                        # for traces of same legend group, show legend for
                        # only the first one of them.
                        $trace->showlegend(0);
                    }
                }

                $plotly->add_trace($trace);
            }

            if ( List::AllUtils::any { $_->$_call_if_can('showlegend') }
                @$panel )
            {
                $plotly_layout{showlegend} = JSON::true;

                # legend title
                #
                # TODO: See if plotly will officially support legend title
                #  https://github.com/plotly/plotly.js/issues/276
                my $br = br();
                my $legend_titles =
                  join( $br, map { $_->title =~ s/\n/$br/gr; } @$gdefs );

                my $annotations = $plotly_layout{annotations} //= [];
                push @$annotations,
                  {
                    x         => 1.02,
                    y         => 1,
                    align     => 'left',
                    xanchor   => 'left',
                    yanchor   => 'bottom',
                    text      => $legend_titles,
                    showarrow => JSON::false,
                    xref      => 'paper',
                    yref      => 'paper',
                  };

                # Default right margin is too small for legend title.
                #
                # TODO: How to automatically calc the margin?
                #  May need to use libraries like Cairo for text width?
                #  Best if plotly can natively support legend title.
                $plotly_layout{margin} = { r => 150 };
            }
        }
    }

    # Above operations already ensures for each legend group there be only
    #  one legend item. So there is no need to keep legendgroup gap, then
    #  it looks better to me compared with having the default gap.
    $plotly_layout{legend} = { tracegroupgap => 0 };

    $plotly_layout{hovermode} = 'closest';
    $plotly_layout{barmode} = $barmode // 'relative';
    
    # border
    my $el_panel_border = $theme->at('panel_border');
    unless ( not defined $el_panel_border or $el_panel_border->is_blank ) {
        $plotly_layout{shapes} = [
            {
                type      => 'rect',
                fillcolor => 'transparent',
                line      => {
                    color    => to_rgb( $el_panel_border->at('color') ),
                    width    => 1,
                    linetype => 'solid',
                },
                xref => 'paper',
                x0   => 0,
                x1   => 1,
                yref => 'paper',
                y0   => 0,
                y1   => 1,
            }
        ];
    }

    if ( $theme->at('legend_position') eq 'none' ) {
        $plotly_layout{showlegend} = JSON::false;
    }

    # colorbar
    my ($colorbar) =
      grep { $_->$_DOES('Chart::GGPlot::Guide::Colorbar') } @$gdefs;
    if ($colorbar) {
        my $colorbar_trace = $self->_colorbar_to_trace($colorbar);
        $plotly->add_trace($colorbar_trace);
    }

    $log->debug( "plotly layout : " . Dumper( \%plotly_layout ) )
      if $log->is_debug;

    $plotly->layout( \%plotly_layout );

    #$log->trace( "plotly html:\n" . $plotly->html ) if $log->is_trace;

    return $plotly;
}


method ggplotly ($ggplot) {
    my $plot_built = $self->build($ggplot);
    return $self->_to_plotly($plot_built);
}

method show ($ggplot, HashRef $opts={}) {
    my $plotly = $self->ggplotly($ggplot);
    show_plot( $plotly );
}

method save ($ggplot, $filename, HashRef $opts={}) {
    my $plotly = $self->ggplotly($ggplot);
    my $good = Chart::Plotly::Image::Orca::orca(
        #<<< no perltidy
                plot => $plotly,
                file => $filename,
        maybe   width => $opts->{width},
        maybe   height => $opts->{height},
        #>>>
    );
    die "Failed to save image via plotly-orca" unless $good;
}

method iplot ($ggplot, HashRef $opts={}) {
    state $plugin_registered;
    unless ($plugin_registered) {
        IPerl->load_plugin('Chart::Plotly');
        $plugin_registered = 1;
    }

    return $self->ggplotly($ggplot);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Chart::GGPlot::Backend::Plotly - Plotly backend for Chart::GGPlot

=head1 VERSION

version 0.0005

=head1 DESCRIPTION

The Plotly backend for Chart::GGPlot.

=head1 METHODS

=head2 ggplotly

    ggplotly($ggplot)

Returns a L<Chart::Plotly> object.

=head2 show

    show($ggplot, HashRef $opts={})

Show the plot in web browser.

On POSIX systems L<Chart::Plotly> internally uses L<Browser::Open> to open
the browser. L<Browser::Open> has a default list of browsers and tries
them one by one. You may want to override that behavior by set env var
C<BROWSER> to force a browser command on your system, for example, 

    export BROWSER=chromium-browser

=head2 save

    save($ggplot, $filename, HashRef $opts={})

Export the plot to a static image file. This internally uses
L<Chart::Plotly::Image::Orca>.

Below options are supported for C<$opts>:

=over 4

=item *

width

=item *

height

=back

=head2 iplot

    iplot($ggplot, HashRef $opts={})

Generate Plotly plot for L<IPerl> in Jupyter notebook.

=head1 SEE ALSO

L<https://plot.ly/|Plotly>

L<Chart::GGPlot::Backend>

L<Chart::Plotly>, L<Chart::Plotly::Image::Orca>

=head1 AUTHOR

Stephan Loyd <sloyd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
