package t::TestCatalystPathing;

use strict;

use base qw/t::TestCatalystBase/;

__PACKAGE__->setup_(
    assets => {
        path => "/static",
        output => "built/%n%-l.%e",
        minify => "minifier",
    },
);

sub auto : Private {
    my ($self, $catalyst) = @_;
    $catalyst->assets->include("auto.css");
    $catalyst->assets->include("auto.js");
}

sub fruit_salad : Path('fruit-salad') {
    my ($self, $catalyst) = @_;
    
    $catalyst->assets->include("apple.js");
    $catalyst->assets->include("banana.js");
    $catalyst->assets->include("apple.css");
    $catalyst->response->output($catalyst->assets->export);
}
1;
