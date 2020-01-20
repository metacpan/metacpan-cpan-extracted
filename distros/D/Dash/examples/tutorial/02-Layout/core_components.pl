#!/usr/bin/env perl 

use strict;
use warnings;
use utf8;

use Dash;
use aliased 'Dash::Core::Components' => 'dcc';
use aliased 'Dash::Html::Components' => 'html';
use JSON;

my $external_stylesheets = ['https://codepen.io/chriddyp/pen/bWLwgP.css'];

my $app = Dash->new(
    app_name             => 'Dash Tutorial - 2 Layout',
    external_stylesheets => $external_stylesheets
);

$app->layout(
    html->Div(
        children => [
            html->Label( children => 'Dropdown' ),
            dcc->Dropdown(
                options => [
                    { 'label' => 'New York City', 'value' => 'NYC' },
                    { 'label' => 'Montréal',     'value' => 'MTL' },
                    { 'label' => 'San Francisco', 'value' => 'SF' }
                ],
                value => 'MTL'
            ),

            html->Label( children => 'Multi-Select Dropdown' ),
            dcc->Dropdown(
                options => [
                    { 'label' => 'New York City', 'value' => 'NYC' },
                    { 'label' => 'Montréal',     'value' => 'MTL' },
                    { 'label' => 'San Francisco', 'value' => 'SF' }
                ],
                value => [ 'MTL', 'SF' ],
                multi => JSON::true
            ),

            html->Label( children => 'Radio Items' ),
            dcc->RadioItems(
                options => [
                    { 'label' => 'New York City', 'value' => 'NYC' },
                    { 'label' => 'Montréal',     'value' => 'MTL' },
                    { 'label' => 'San Francisco', 'value' => 'SF' }
                ],
                value => 'MTL'
            ),

            html->Label( children => 'Checkboxes' ),
            dcc->Checklist(
                options => [
                    { 'label' => 'New York City', 'value' => 'NYC' },
                    { 'label' => 'Montréal',     'value' => 'MTL' },
                    { 'label' => 'San Francisco', 'value' => 'SF' }
                ],
                value => [ 'MTL', 'SF' ]
            ),

            html->Label( children => 'Text Input' ),
            dcc->Input( value => 'MTL', type => 'text' ),

            html->Label( children => 'Slider' ),
            dcc->Slider(
                min   => 0,
                max   => 9,
                marks => [
                    map {
                        { $_ => 'Label ' . $_ }
                    } 1 .. 9
                ],
                value => 5,
            ),
        ],
        style => { 'columnCount' => 2 }
    )
);

$app->run_server();

