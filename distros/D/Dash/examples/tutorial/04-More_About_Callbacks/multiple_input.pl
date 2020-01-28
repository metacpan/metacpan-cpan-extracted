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
            dcc->Input( id => 'input-1', type => 'text', value => 'Montréal' ),
            dcc->Input( id => 'input-2', type => 'text', value => 'Canada' ),
            html->Div( id => 'number-output' )
        ]
    )
);

$app->callback(
    deps->Output( 'number-output', 'children' ),
    [ deps->Input( 'input-1', 'value' ), deps->Input( 'input-2', 'value' ) ],
    sub {
        my ( $input1, $input2 ) = @_;
        return 'Input 1 is "' . $input1 . '" and Input 2 is "' . $input2 . '"';
    }
);

$app->run_server();
