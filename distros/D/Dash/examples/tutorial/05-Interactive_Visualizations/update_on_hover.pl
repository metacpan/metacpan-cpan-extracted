#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Dash;
use aliased 'Dash::Core::Components' => 'dcc';
use aliased 'Dash::Html::Components' => 'html';
use aliased 'Dash::Dependencies'     => 'deps';

use IO::All;
use Alt::Data::Frame::ButMore;
use Data::Frame;
use PDL::Primitive;

my $external_stylesheets = ['https://codepen.io/chriddyp/pen/bWLwgP.css'];

my $df = Data::Frame->from_csv(
    io('https://plotly.github.io/datasets/country_indicators.csv')->tie );

my $available_indicators = $df->at('Indicator Name')->uniq->unpdl;

my $app = Dash->new(
    app_name             => 'Dash Tutorial - 3 Basic Callbacks',
    external_stylesheets => $external_stylesheets
);

$app->layout(
    html->Div(
        [
            html->Div(
                [
                    html->Div(
                        [
                            dcc->Dropdown(
                                id      => 'crossfilter-xaxis-column',
                                options => [
                                    map { { label => $_, value => $_ } }
                                      @$available_indicators
                                ],
                                value =>
                                  'Fertility rate, total (births per woman)'
                            ),
                            dcc->RadioItems(
                                id      => 'crossfilter-xaxis-type',
                                options => [
                                    map { { label => $_, value => $_ } }
                                      qw(Linear Log)
                                ],
                                value      => 'Linear',
                                labelStyle => { display => 'inline-block' }
                            )
                        ],
                        style => { width => '49%', display => 'inline-block' }
                    ),
                    html->Div(
                        [
                            dcc->Dropdown(
                                id      => 'crossfilter-yaxis-column',
                                options => [
                                    map { { label => $_, value => $_ } }
                                      @$available_indicators
                                ],
                                value =>
                                  'Life expectancy at birth, total (years)'
                            ),
                            dcc->RadioItems(
                                id      => 'crossfilter-yaxis-type',
                                options => [
                                    map { { label => $_, value => $_ } }
                                      qw(Linear Log)
                                ],
                                value      => 'Linear',
                                labelStyle => { display => 'inline-block' }
                            )
                        ],
                        style => {
                            width   => '49%',
                            float   => 'right',
                            display => 'inline-block'
                        }
                    )
                ],
                style => {
                    borderBottom    => 'thin lightgrey solid',
                    backgroundColor => 'rgb(250, 250, 250)',
                    padding         => '10px 5px'

                }
            ),

            html->Div(
                dcc->Graph(
                    id        => 'crossfilter-indicator-scatter',
                    hoverData => { points => [ { customdata => 'Japan' } ] }
                ),
                style => {
                    width   => '49%',
                    display => 'inline-block',
                    padding => '0 20'
                }
            ),
            html->Div(
                [
                    dcc->Graph( id => 'x-time-series' ),
                    dcc->Graph( id => 'y-time-series' ),
                ],
                style => { display => 'inline-block', width => '49%' }
            ),

            html->Div(
                dcc->Slider(
                    id    => 'crossfilter-year--slider',
                    min   => $df->at('Year')->min,
                    max   => $df->at('Year')->max,
                    value => $df->at('Year')->max,
                    marks =>
                      { map { $_ => $_ } @{ $df->at('Year')->uniq->unpdl } },
                    step => JSON::null
                ),
                style => { width => '49%', padding => '0px 20px 20px 20px' }
            )
        ]
    )
);

$app->callback(
    deps->Output( 'crossfilter-indicator-scatter', 'figure' ),
    [
        deps->Input( 'crossfilter-xaxis-column', 'value' ),
        deps->Input( 'crossfilter-yaxis-column', 'value' ),
        deps->Input( 'crossfilter-xaxis-type',   'value' ),
        deps->Input( 'crossfilter-yaxis-type',   'value' ),
        deps->Input( 'crossfilter-year--slider', 'value' )
    ],
    sub {
        my ( $xaxis_column_name, $yaxis_column_name, $xaxis_type, $yaxis_type,
            $year_value )
          = @_;
        my $dff = $df->select_rows( which( $df->at('Year') == $year_value ) );
        return {
            data => [
                {
                    x => $dff->select_rows(
                        which(
                            $dff->at('Indicator Name') eq $xaxis_column_name
                        )
                    )->at('Value')->unpdl,
                    y => $dff->select_rows(
                        which(
                            $dff->at('Indicator Name') eq $yaxis_column_name
                        )
                    )->at('Value')->unpdl,
                    text => $dff->select_rows(
                        which(
                            $dff->at('Indicator Name') eq $yaxis_column_name
                        )
                    )->at('Country Name')->unpdl,
                    customdata => $dff->select_rows(
                        which(
                            $dff->at('Indicator Name') eq $yaxis_column_name
                        )
                    )->at('Country Name')->unpdl,
                    mode   => 'markers',
                    marker => {
                        size    => 15,
                        opacity => 0.5,
                        line    => { width => 0.5, color => 'white' }
                    }
                }
            ],
            layout => {
                xaxis => {
                    title => $xaxis_column_name,
                    type  => lc($xaxis_type)
                },
                yaxis => {
                    title => $yaxis_column_name,
                    type  => lc($yaxis_type)
                },
                margin    => { l => 40, b => 40, t => 10, r => 0 },
                hovermode => 'closest'
            }
        };
    }
);

sub create_time_series {
    my ( $dff, $axis_type, $title ) = @_;
    return {
        data => [
            {
                x    => $dff->at('Year')->unpdl,
                y    => $dff->at('Value')->unpdl,
                mode => 'lines+markers'
            }
        ],
        layout => {
            height      => 225,
            margin      => { l => 20, b => 30, r => 10, t => 10 },
            annotations => [
                {
                    x         => 0,
                    y         => 0.85,
                    xanchor   => 'left',
                    yanchor   => 'bottom',
                    xref      => 'paper',
                    yref      => 'paper',
                    showarrow => JSON::false,
                    align     => 'left',
                    bgcolor   => 'rgba(255, 255, 255, 0.5)',
                    text      => $title

                }
            ],
            yaxis => { type     => lc($axis_type) },
            xaxis => { showgrid => JSON::false }
        }
    };
}

$app->callback(
    deps->Output( 'x-time-series', 'figure' ),
    [
        deps->Input( 'crossfilter-indicator-scatter', 'hoverData' ),
        deps->Input( 'crossfilter-xaxis-column',      'value' ),
        deps->Input( 'crossfilter-xaxis-type',        'value' ),
    ],
    sub {
        my ( $hoverData, $xaxis_column_name, $axis_type ) = @_;
        my $country_name = $hoverData->{points}[0]{'customdata'};
        my $dff =
          $df->select_rows( which( $df->at('Country Name') eq $country_name ) );
        $dff = $dff->select_rows(
            which( $dff->at('Indicator Name') eq $xaxis_column_name ) );
        my $title = '<b>' . $country_name . '</b><br>' . $xaxis_column_name;
        return create_time_series( $dff, $axis_type, $title );
    }
);

$app->callback(
    deps->Output( 'y-time-series', 'figure' ),
    [
        deps->Input( 'crossfilter-indicator-scatter', 'hoverData' ),
        deps->Input( 'crossfilter-yaxis-column',      'value' ),
        deps->Input( 'crossfilter-yaxis-type',        'value' ),
    ],
    sub {
        my ( $hoverData, $yaxis_column_name, $axis_type ) = @_;
        my $country_name = $hoverData->{points}[0]{'customdata'};
        my $dff =
          $df->select_rows( which( $df->at('Country Name') eq $country_name ) );
        $dff = $dff->select_rows(
            which( $dff->at('Indicator Name') eq $yaxis_column_name ) );
        return create_time_series( $dff, $axis_type, $yaxis_column_name );
    }
);

$app->run_server();
