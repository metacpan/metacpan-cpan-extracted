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
                                id      => 'xaxis-column',
                                options => [
                                    map { { label => $_, value => $_ } }
                                      @$available_indicators
                                ],
                                value =>
                                  'Fertility rate, total (births per woman)'
                            ),
                            dcc->RadioItems(
                                id      => 'xaxis-type',
                                options => [
                                    map { { label => $_, value => $_ } }
                                      qw(Linear Log)
                                ],
                                value      => 'Linear',
                                labelStyle => { display => 'inline-block' }
                            )
                        ],
                        style => { width => '48%', display => 'inline-block' }
                    ),
                    html->Div(
                        [
                            dcc->Dropdown(
                                id      => 'yaxis-column',
                                options => [
                                    map { { label => $_, value => $_ } }
                                      @$available_indicators
                                ],
                                value =>
                                  'Life expectancy at birth, total (years)'
                            ),
                            dcc->RadioItems(
                                id      => 'yaxis-type',
                                options => [
                                    map { { label => $_, value => $_ } }
                                      qw(Linear Log)
                                ],
                                value      => 'Linear',
                                labelStyle => { display => 'inline-block' }
                            )
                        ],
                        style => {
                            width   => '48%',
                            float   => 'right',
                            display => 'inline-block'
                        }
                    )
                ]
            ),
            dcc->Graph( id => 'indicator-graphic' ),

            dcc->Slider(
                id    => 'year--slider',
                min   => $df->at('Year')->min,
                max   => $df->at('Year')->max,
                value => $df->at('Year')->max,
                marks => { map { $_ => $_ } @{ $df->at('Year')->uniq->unpdl } },
                step  => JSON::null
            )
        ]
    )
);

$app->callback(
    deps->Output( 'indicator-graphic', 'figure' ),
    [
        deps->Input( 'xaxis-column', 'value' ),
        deps->Input( 'yaxis-column', 'value' ),
        deps->Input( 'xaxis-type',   'value' ),
        deps->Input( 'yaxis-type',   'value' ),
        deps->Input( 'year--slider', 'value' )
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

$app->run_server();
