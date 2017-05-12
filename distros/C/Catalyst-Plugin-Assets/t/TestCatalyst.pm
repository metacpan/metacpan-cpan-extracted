package t::TestCatalyst;

use strict;

use base qw/t::TestCatalystBase/;

__PACKAGE__->setup_(
    'Plugin::Assets' => {
        output_path => [
            [ ":yuicompressor" => "static/yui-compressor/%n%-l.%e" ],
            [ ":concat" => "static/concat/%n%-l.%e" ],
        ],
    },
);

sub yui_compressor :Path('yui-compressor') {
    my ($self, $catalyst) = @_;
    
    $catalyst->assets->filter(css => "yuicompressor:./yuicompressor.jar");
    $catalyst->assets->include("static/yui-compressor.css");
    $catalyst->assets->include("static/yui-compressor.js");
    $catalyst->response->output($catalyst->assets->export);
}

sub concat :Path('concat') {
    my ($self, $catalyst) = @_;
    
    $catalyst->assets->filter("concat");
    $catalyst->assets->include("static/concat.css");
    $catalyst->assets->include("static/concat.js");
    $catalyst->response->output($catalyst->assets->export);
}

1;
