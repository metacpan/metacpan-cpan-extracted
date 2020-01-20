use Dash;
use aliased 'Dash::Html::Components' => 'html';
use aliased 'Dash::Core::Components' => 'dcc';

my $external_stylesheets = ['https://codepen.io/chriddyp/pen/bWLwgP.css'];

my $app = Dash->new(
    app_name             => 'Chained Callbacks',
    external_stylesheets => $external_stylesheets
);

my $all_options = {
    America => ['New York City', 'San Francisco', 'Cincinnati'],
    Canada => ['Montréal', 'Toronto', 'Ottawa']
};

$app->layout(
    html->Div(children => [
        dcc->RadioItems(id => 'countries-radio', 
            options => [map {{ label => $_, value => $_}} keys %$all_options],
            value => 'America'),
        html->Hr(),
        dcc->RadioItems(id => 'cities-radio'),
        html->Hr(),
        html->Div(id => 'display-selected-values')
    ])
);

$app->callback(
    Output => {component_id => 'cities-radio', component_property => 'options'},
    Inputs => [{component_id=>'countries-radio', component_property=> 'value'}],
    callback => sub {
        my $selected_country = shift;
        return [map {{label => $_, value => $_}} @{$all_options->{$selected_country}}]
    }
);

$app->callback(
    Output => {component_id => 'cities-radio', component_property => 'value'},
    Inputs => [{component_id=>'cities-radio', component_property=> 'options'}],
    callback => sub {
        my $available_options = shift;
        return $available_options->[0]{value};
    }
);

$app->callback(
    Output => {component_id => 'display-selected-values', component_property => 'children'},
    Inputs => [{component_id=>'countries-radio', component_property=> 'value'},
            {component_id=>'cities-radio', component_property=> 'value'},
                ],
    callback => sub {
        my $selected_country = shift;
        my $selected_city = shift;
        return "$selected_city is a city in $selected_country";;
    }
);

$app->run_server();

