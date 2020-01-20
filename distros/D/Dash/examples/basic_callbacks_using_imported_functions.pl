use Dash;

# Every component suite gets a package with all the components with
# factory methods to avoid loading one by one the components
# That is: Dash::Html::ComponentsFunctions load
# one factory method for component, for example
# Div() calls Dash::Html::Components::Div->new()
use Dash::Html::ComponentsFunctions;
use Dash::Core::ComponentsFunctions;

my $external_stylesheets = ['https://codepen.io/chriddyp/pen/bWLwgP.css'];

my $app = Dash->new(
    app_name             => 'Basic Callbacks',
    external_stylesheets => $external_stylesheets
);

my $initial_number_of_values = 20;
$app->layout(
    Div(children => [
        Input(id => 'my-id', value => $initial_number_of_values, type => 'number'),
        Graph(id => 'my-graph')
    ])
);

my $serie = [ map { rand(100) } 1 .. $initial_number_of_values];
$app->callback(
    Output => {component_id => 'my-graph', component_property => 'figure'},
    Inputs => [{component_id=>'my-id', component_property=> 'value'}],
    callback => sub {
        my $number_of_elements = shift;
        my $size_of_serie = scalar @$serie;
        if ($number_of_elements >= $size_of_serie) {
            push @$serie, map { rand(100) } $size_of_serie .. $number_of_elements;
        } else {
            @$serie = @$serie[0 .. $number_of_elements];
        }
        return { data => [ {
            type => "scatter",
            y => $serie
            }]};
    }
);

$app->run_server();

