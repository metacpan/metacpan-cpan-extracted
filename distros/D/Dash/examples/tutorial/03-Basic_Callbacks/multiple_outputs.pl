#!/usr/bin/env perl 

use strict;
use warnings;
use utf8;

use Dash;
use aliased 'Dash::Core::Components' => 'dcc';
use aliased 'Dash::Html::Components' => 'html';

my $external_stylesheets = ['https://codepen.io/chriddyp/pen/bWLwgP.css'];

my $app = Dash->new(app_name => 'Dash Tutorial - 2 Layout', external_stylesheets=>$external_stylesheets);

$app->layout( html->Div(children=>[
    dcc->Input( id => 'num-multi',
        type => 'number',
        value => 5),
    html->Table(children => [
        html->Tr(children => [html->Td(children => ['x', html->Sup(children => 2)]), html->Td(id => 'square')]),
        html->Tr(children => [html->Td(children => ['x', html->Sup(children => 3)]), html->Td(id => 'cube')]),
        html->Tr(children => [html->Td(children => [2, html->Sup(children => 'x')]), html->Td(id => 'twos')]),
        html->Tr(children => [html->Td(children => [3, html->Sup(children => 'x')]), html->Td(id => 'threes')]),
        html->Tr(children => [html->Td(children => ['x', html->Sup(children => 'x')]), html->Td(id => 'x^x')]),
        ])
]));

$app->callback(
    Output => [
        { component_id => 'square', component_property => 'children' },
        { component_id => 'cube',   component_property => 'children' },
        { component_id => 'twos',   component_property => 'children' },
        { component_id => 'threes', component_property => 'children' },
        { component_id => 'x^x',    component_property => 'children' },
    ],
    Inputs =>
      [ { component_id => 'num-multi', component_property => 'value' } ],
    callback => sub {
        my $x = shift;
        return $x**2, $x**3, 2**$x, 3**$x, $x**$x;
    }
);

$app->run_server();

