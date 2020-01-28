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
    io(
'https://raw.githubusercontent.com/plotly/datasets/master/gapminderDataFiveYear.csv'
    )->tie
);

my $app = Dash->new(
    app_name             => 'Dash Tutorial - 3 Basic Callbacks',
    external_stylesheets => $external_stylesheets
);

$app->layout(
    html->Div(
        [
            dcc->Graph( id => 'graph-with-slider' ),
            dcc->Slider(
                id    => 'year-slider',
                min   => $df->at('year')->min,
                max   => $df->at('year')->max,
                value => $df->at('year')->min,
                marks => { map { $_ => $_ } @{ $df->at('year')->uniq->unpdl } },
                step  => JSON::null
            )
        ]
    )
);

$app->callback(
    deps->Output( 'graph-with-slider', 'figure' ),
    [ deps->Input( 'year-slider', 'value' ) ],
    sub {
        my $selected_year = shift;
        my $filtered_df =
          $df->select_rows( which( $df->at('year') == $selected_year ) );
        my $traces = [];
        for my $continent ( @{ $filtered_df->at('continent')->uniq->unpdl } ) {
            my $df_by_continent = $filtered_df->select_rows(
                which( $filtered_df->at('continent') eq $continent ) );
            push @$traces,
              {
                x       => $df_by_continent->at('gdpPercap')->unpdl,
                y       => $df_by_continent->at('lifeExp')->unpdl,
                text    => $df_by_continent->at('country')->unpdl,
                mode    => 'markers',
                opacity => 0.7,
                marker  => {
                    size => 15,
                    line => { width => 0.5, color => 'white' }
                },
                name => $continent,
              };
        }
        return {
            data   => $traces,
            layout => {
                xaxis => {
                    type  => 'log',
                    title => 'GDP Per Capita',
                    range => [ 2.3, 4.8 ]
                },
                yaxis => { title => 'Life Expectancy', range => [ 20, 90 ] },
                margin => { l => 40, b => 40, t => 10, r => 10 },
                legend => { x => 0,  y => 1 },
                hovermode  => 'closest',
                transition => { duration => 500 },
            }
        };
    }
);

$app->run_server();
