package t::TestCatalystBase;

use strict;

use Catalyst;
use Directory::Scratch;

my %content = (
);

my $scratch = Directory::Scratch->new;
$scratch->create_tree({

    (map { $_ => "/* Test css file for $_ */\n" } map { "root/static/$_.css" } qw/apple banana auto yui-compressor concat/),

    (map { $_ => "/* Test js file for $_ */\n" } map { "root/static/$_.js" } qw/apple banana auto yui-compressor concat/),

    'root/static/apple.css' => <<_END_,
/* Test css file for apple.css */

div.apple {
    color: red;
}

div.apple {
    color: blue;
}
_END_

    'root/static/auto.css' => <<_END_,
/* Test css file for auto.css */

div.auto {
    font-weight: bold;
    color: green;
}

/* Comment at the end */
_END_

    'root/static/apple.js' => <<_END_,
/* Test js file for apple.js */

var apple = 1 + 4;

alert("Apple is " + apple);

_END_

    'root/static/auto.js' => <<_END_,
/* Test js file for auto.js */

function calculate() {
    return 1 * 30 / 23;
}

var auto = 8 + 4;

alert("Automatically " + auto);
_END_

});

sub scratch {
    return $scratch;
}

sub setup_ {
    my $class = shift;

    $class->config(
        home => $scratch->base,
        name => 'TestCatalyst',
        debug => 1,
        @_,
    );

    $class->setup(qw/Assets/);
}

sub auto : Private {
    my ($self, $catalyst) = @_;
    $catalyst->assets->include("static/auto.css");
    $catalyst->assets->include("static/auto.js");
}

sub default : Private {
    my ($self, $catalyst) = @_;
    
    $catalyst->response->output('Nothing happens.');
}

sub fruit_salad : Path('fruit-salad') {
    my ($self, $catalyst) = @_;
    
    $catalyst->assets->include("static/apple.js");
    $catalyst->assets->include("static/banana.js");
    $catalyst->assets->include("static/apple.css");
    $catalyst->response->output($catalyst->assets->export);
}

1;
