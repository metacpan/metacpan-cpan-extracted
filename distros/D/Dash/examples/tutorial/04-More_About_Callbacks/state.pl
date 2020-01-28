#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Dash;
use aliased 'Dash::Core::Components' => 'dcc';
use aliased 'Dash::Html::Components' => 'html';
use aliased 'Dash::Dependencies'     => 'deps';

my $external_stylesheets = ['https://codepen.io/chriddyp/pen/bWLwgP.css'];

my $app = Dash->new(
    app_name             => 'Dash Tutorial - 4 More About Callbacks: State',
    external_stylesheets => $external_stylesheets
);

$app->layout(
    html->Div(
        [
            dcc->Input(
                id    => 'input-1-state',
                type  => 'text',
                value => 'Montréal'
            ),
            dcc->Input(
                id    => 'input-2-state',
                type  => 'text',
                value => 'Canada'
            ),
            html->Button(
                id       => 'submit-button',
                n_clicks => 0,
                children => 'Submit'
            ),
            html->Div( id => 'output-state' )
        ]
    )
);

$app->callback(
    deps->Output( 'output-state', 'children' ),
    [ deps->Input( 'submit-button', 'n_clicks' ) ],
    [
        deps->State( 'input-1-state', 'value' ),
        deps->State( 'input-2-state', 'value' )
    ],
    sub {
        my ( $n_clicks, $input1, $input2 ) = @_;
        return
            "The Button has been pressed $n_clicks times "
          . 'Input 1 is "'
          . $input1
          . '" and Input 2 is "'
          . $input2 . '"';
    }
);

$app->run_server();
