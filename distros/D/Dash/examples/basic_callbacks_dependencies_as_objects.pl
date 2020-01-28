use Dash;
use aliased 'Dash::Html::Components' => 'html';
use aliased 'Dash::Core::Components' => 'dcc';
use aliased 'Dash::Dependencies' => 'deps';

my $external_stylesheets = ['https://codepen.io/chriddyp/pen/bWLwgP.css'];

my $app = Dash->new(
    app_name             => 'Basic Callbacks',
    external_stylesheets => $external_stylesheets
);

$app->layout(
    html->Div(children => [
        dcc->Input(id => 'my-id', value => 'initial value', type => 'text'),
        html->Div(id => 'my-div')
    ])
);

$app->callback(
    deps->Output(component_id => 'my-div', component_property => 'children'),
    [deps->Input('my-id', 'value')],
    sub {
        my $input_value = shift;
        return "You've entered '$input_value'";
    }
);

$app->run_server();

