#!/usr/bin/env perl -w

use strict;
use warnings;
use utf8;

use Test::More tests => 3;

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
#  4. ClientSide

{
    my $test_app = Dash->new;

    $test_app->layout(
                       html->Div(
                                 children => [ dcc->Input( id => 'input-id', value => 'initial value', type => 'text' ),
                                               html->Div( id => 'output-id' )
                                 ]
                       )
    );

    $test_app->callback(
        Output   => { component_id => 'output-id', component_property => 'children' },
        Inputs   => [ { component_id => 'input-id', component_property => 'value' } ],
        callback => sub {
            my $input_value = shift;
            return "You've entered '$input_value'";
        }
    );

    IsStructureEqualJSON(
        $test_app->_dependencies,
        '[{"clientside_function":null,"inputs":[{"id":"input-id","property":"value"}],"output":"output-id.children","state":[]}]',
        'Simple output dependency'
    );
}

{
    my $test_app = Dash->new;

    $test_app->layout(
                       html->Div(
                                 children => [ dcc->Input( id => 'input-id', value => 'initial value', type => 'text' ),
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
            return "You've entered '$input_value'", $input_value;
        }
    );

    IsStructureEqualJSON(
        $test_app->_dependencies,
        '[{"clientside_function":null,"inputs":[{"id":"input-id","property":"value"}],"output":"..output-id.children...second-output-id.children..","state":[]}]',
        'Multiple output dependency'
    );
}

{
    my $test_app = Dash->new;

    $test_app->layout(
                       html->Div(
                            children => [ dcc->Input( id => 'input-id', value => 'initial value',      type => 'text' ),
                                          dcc->Input( id => 'second-input-id', value => 'state value', type => 'text' ),
                                          html->Div( id => 'output-id' )
                            ]
                       )
    );

    $test_app->callback(
        Output   => { component_id => 'output-id', component_property => 'children' },
        Inputs   => [ { component_id => 'input-id',        component_property => 'value' } ],
        State    => [ { component_id => 'second-input-id', component_property => 'value' } ],
        callback => sub {
            my ( $input_value, $second_input_value ) = @_;
            return "You've entered '$input_value' and '$second_input_value'";
        }
    );

    IsStructureEqualJSON(
        $test_app->_dependencies,
        '[{"clientside_function":null,"inputs":[{"id":"input-id","property":"value"}],"output":"output-id.children","state":[{"id":"second-input-id","property":"value"}]}]',
        'State dependency'
    );
}

