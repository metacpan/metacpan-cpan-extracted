#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Dash;
use aliased 'Dash::Core::Components' => 'dcc';
use aliased 'Dash::Html::Components' => 'html';
use aliased 'Dash::Dependencies'     => 'deps';
use Dash::Exceptions::PreventUpdate;

my $external_stylesheets = ['https://codepen.io/chriddyp/pen/bWLwgP.css'];

my $app = Dash->new(
    app_name             => 'Dash Tutorial - 4 More About Callbacks: Prevent Update',
    external_stylesheets => $external_stylesheets
);

$app->layout(
    html->Div(
        [
            html->Button(
                'Click here to see the content',
                id       => 'show-secret',
            ),
            html->Div( id => 'body-div' )
        ]
    )
);

$app->callback(
    deps->Output( 'body-div', 'children' ),
    [ deps->Input( 'show-secret', 'n_clicks' ) ],
    sub {
        my $n_clicks = shift;
        if (! defined $n_clicks) {
            Dash::Exceptions::PreventUpdate->throw();
        } else {
            return "Elephants are the only animal that can't jump";
        }
    }
);

$app->run_server();
