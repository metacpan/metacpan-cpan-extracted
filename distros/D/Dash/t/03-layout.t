#!/usr/bin/env perl -w

use strict;
use warnings;
use utf8;

use Test::Most tests => 3;

use Dash;
use JSON;
use aliased 'Dash::Html::Components' => 'html';

# Tests TODO:
#  3. Layout function based

my $test_app = Dash->new;

throws_ok { $test_app->layout( [] ) } qr/Layout must be a dash component or a function that returns a dash component/,
  "Layout can't be array based";

throws_ok { $test_app->layout( {} ) } qr/Layout must be a dash component or a function that returns a dash component/,
  "Layout can't be hash based";

$test_app->layout(
     html->Div(
         children => [ html->Textarea( id => 'input-id', children => 'initial value' ), html->Div( id => 'output-id' ) ]
     )
);

my $json = JSON->new->convert_blessed(1);

is_deeply(
    $json->decode( $json->encode( $test_app->layout ) ),
    $json->decode(
        '{"props": {"children": [{"props": {"children": "initial value", "id": "input-id"}, "type": "Textarea", "namespace": "dash_html_components"}, {"props": {"children": null, "id": "output-id"}, "type": "Div", "namespace": "dash_html_components"}]}, "type": "Div", "namespace": "dash_html_components"}'
    )
);

