#!/usr/bin/env perl 

use strict;
use warnings;
use utf8;

use Dash;
use aliased 'Dash::Core::Components' => 'dcc';
use aliased 'Dash::Html::Components' => 'html';
use IO::All;
use Alt::Data::Frame::ButMore;
use Data::Frame;
use PDL::Primitive;

my $external_stylesheets = ['https://codepen.io/chriddyp/pen/bWLwgP.css'];

my $df = Data::Frame->from_csv(
    io(
'https://gist.githubusercontent.com/chriddyp/5d1ea79569ed194d432e56108a04d188/raw/a9f9e8076b837d541398e999dcbac2b2826a81f8/gdp-life-exp-2007.csv'
    )->tie
);

my $app = Dash->new(
    app_name             => 'Dash Tutorial - 2 Layout',
    external_stylesheets => $external_stylesheets
);

$app->layout(
    html->Div(
        dcc->Graph(
            id     => 'life-exp-vs-gdp',
            figure => {
                data   => [map {{
                        x => $df->select_rows(which($df->at('continent') eq $_))->at('gdp per capita')->unpdl,
                        y => $df->select_rows(which($df->at('continent') eq $_))->at('life expectancy')->unpdl,
                        text => $df->select_rows(which($df->at('continent') eq $_))->at('country')->unpdl,
                        mode => 'markers',
                        opacity => 0.7,
                        marker => {
                            size => 15,
                            line => {width => 0.5, color => 'white'}
                        },
                        name => $_, 
                        }} @{$df->at('continent')->uniq->unpdl}],
                layout => {
                    xaxis  => { type  => 'log', title => 'GDP Per Capita' },
                    yaxis  => { title => 'Life Expectancy' },
                    margin => { l     => 40, b => 40, t => 10, r => 10 },
                    legend => { x     => 0, y => 1 },
                    hovermode => 'closest'
                }
            }
        )
    )
);

$app->run_server();

