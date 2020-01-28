#!/usr/bin/env perl -w

use strict;
use warnings;
use utf8;

use Test::More tests => 4;

use Dash;
use JSON;
use aliased 'Dash::Html::Components' => 'html';
use aliased 'Dash::Core::Components' => 'dcc';

sub IsStructureEqualJSON {
    my ( $structure, $json_string, $test_name ) = @_;

    my $json = JSON->new->convert_blessed(1);
    is_deeply( $json->decode( $json->encode($structure) ), $json->decode($json_string), $test_name );
}

# Tests TODO:
#  4. Update component clientside function
#  5. Update component chained callbacks

{
    my $test_app = Dash->new;

    $test_app->layout(
                       html->Div(
                                  children => [dcc->Input( id => 'input-id', value => 'initial value', type => 'text' ),
                                               html->Div( id => 'output-id' )
                                  ]
                       )
    );

    $test_app->callback(
        Output   => { component_id => 'output-id', component_property => 'children' },
        Inputs   => [ { component_id => 'input-id', component_property => 'value' } ],
        callback => sub {
            my $input_value = shift;
            return "You have entered $input_value";
        }
    );

    my $input_update_component =
      '{"output":"output-id.children","changedPropIds":["input-id.value"],"inputs":[{"id":"input-id","property":"value","value":"initial value"}]}';

    IsStructureEqualJSON( $test_app->_update_component( from_json($input_update_component) ),
                          '{"response": {"props": {"children": "You have entered initial value"}}}',
                          'Update component with simple output dependency'
    );
}

{
    my $test_app = Dash->new;

    $test_app->layout(
                       html->Div(
                                  children => [dcc->Input( id => 'input-id', value => 'initial value', type => 'text' ),
                                               html->Div( id => 'output-id' ),
                                               html->Div( id => 'second-output-id' )
                                  ]
                       )
    );

    $test_app->callback(
        Output => [ { component_id => 'output-id',        component_property => 'children' },
                    { component_id => 'second-output-id', component_property => 'children' }
        ],
        Inputs   => [ { component_id => 'input-id', component_property => 'value' } ],
        callback => sub {
            my $input_value = shift;
            return "You have entered $input_value", $input_value;
        }
    );

    my $input_update_component =
      '{"output":"..output-id.children...second-output-id.children..","changedPropIds":["input-id.value"],"inputs":[{"id":"input-id","property":"value","value":"initial value"}]}';

    IsStructureEqualJSON(
        $test_app->_update_component( from_json($input_update_component) ),
        '{"response": {"output-id": {"children": "You have entered initial value"}, "second-output-id": {"children": "initial value"}}, "multi": true}',
        'Update componente with multiple output dependency'
    );
}

{
    my $test_app = Dash->new;

    $test_app->layout(
                       html->Div(
                                  children => [
                                          dcc->Input( id => 'input-id', value => 'initial value', type => 'text' ),
                                          dcc->Input( id => 'second-input-id', value => 'state value', type => 'text' ),
                                          html->Div( id => 'output-id' )
                                  ]
                       )
    );

    $test_app->callback(
        Output   => { component_id => 'output-id', component_property => 'children' },
        Inputs   => [ { component_id => 'input-id', component_property => 'value' } ],
        State    => [ { component_id => 'second-input-id', component_property => 'value' } ],
        callback => sub {
            my ( $input_value, $second_input_value ) = @_;
            return "You have entered $input_value and $second_input_value";
        }
    );

    my $input_update_component =
      '{"output":"output-id.children","changedPropIds":["input-id.value"],"inputs":[{"id":"input-id","property":"value","value":"initial value"}],"state":[{"id":"second-input-id","property":"value","value":"state value"}]}';

    IsStructureEqualJSON( $test_app->_update_component( from_json($input_update_component) ),
                          '{"response": {"props": {"children": "You have entered initial value and state value"}}}',
                          'Update component with state dependency' );
}

{
    my $test_app = Dash->new;

    $test_app->layout(
                       html->Div(
                                  children => [dcc->Input( id => 'input-id', value => 'initial value', type => 'text' ),
                                               html->Div( id => 'output-id' )
                                  ]
                       )
    );

    my $context_output;
    $test_app->callback(
        Output   => { component_id => 'output-id', component_property => 'children' },
        Inputs   => [ { component_id => 'input-id', component_property => 'value' } ],
        callback => sub {
            my $input_value = shift;
            my $context     = shift;
            $context_output = $context;
            return "You have entered $input_value";
        }
    );

    my $input_update_component =
      '{"output":"output-id.children","changedPropIds":["input-id.value"],"inputs":[{"id":"input-id","property":"value","value":"initial value"}]}';
    $test_app->_update_component( from_json($input_update_component) );
    is_deeply( $context_output,
               { inputs    => { 'input-id.value' => 'initial value' },
                 triggered => [ { prop_id => 'input-id.value', value => 'initial value' } ]
               },
               'Context is correctly received by the callback'
    );
}

