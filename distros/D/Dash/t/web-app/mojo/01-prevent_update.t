use Mojo::Base -strict;

use Test::Mojo;
use Test::More tests => 3;

use aliased 'Dash::Core::Components' => 'dcc';
use aliased 'Dash::Html::Components' => 'html';
use Dash::Exceptions::PreventUpdate;

use Dash;

my $app = Dash->new();

my $t = Test::Mojo->new( $app->backend );

$app->layout(
      html->Div(
          children =>
            [ dcc->Input( id => 'input-id', value => 'initial value', type => 'text' ), html->Div( id => 'output-id' ) ]
      )
);

$app->callback(
    Output   => { component_id => 'output-id', component_property => 'children' },
    Inputs   => [ { component_id => 'input-id', component_property => 'value' } ],
    callback => sub {
        Dash::Exceptions::PreventUpdate->throw;
    }
);

$t->post_ok(
             '/_dash-update-component' => json => {
                                       output         => 'output-id.children',
                                       changedPropIds => ['input-id.value'],
                                       inputs => [ { id => 'input-id', property => 'value', value => 'initial value' } ]
             }
)->status_is(204)->json_is();

