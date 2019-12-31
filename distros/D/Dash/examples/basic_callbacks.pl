use Dash;
use aliased 'Dash::Html::Components::Div';
use aliased 'Dash::Html::Components::H1';
use aliased 'Dash::Core::Components::Input';

my $external_stylesheets = ['https://codepen.io/chriddyp/pen/bWLwgP.css'];

my $app = Dash->new(
    app_name             => 'Basic Callbacks',
    external_stylesheets => $external_stylesheets
);

$app->layout(
    Div->new(children => [
        H1->new(children => 'Titulo'),
        Input->new(id => 'my-id', value => 'initial value', type => 'text'),
        Div->new(id => 'my-div')
    ])
);

$app->callback(
    Output => {component_id => 'my-div', component_property => 'children'},
    Inputs => [{component_id=>'my-id', component_property=> 'value'}],
    callback => sub {
        my $input_value = shift;
        return "You've entered \"$input_value\"";
    }
);

$app->run_server();

