package App::HistHub::Web::View::TD::Templates;
use strict;
use warnings;
use Template::Declare::Tags;

template 'index' => sub {
    my ($self, $c) = @_;
    html {
        head {
            title { 'App-HistHub' };
        };
        body {
            "TODO: make this page"
        };
    };
};

1;

