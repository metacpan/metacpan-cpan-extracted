package t::lib::TestApp;

use Dancer;
use Dancer::Plugin::EscapeHTML;

use Foo;

setting 'template' => 'Simple';
setting 'show_errors' => 1;

get '/straight' => sub {
    return template 'index', { foo => "<p>Foo</p>" };
};

get '/escaped' => sub {
    return template 'index', { foo => escape_html("<p>Foo</p>") };
};

get '/excluded' => sub {
    return template 'excluded', { foo_html => "<p>Foo</p>" };
};

get '/object' => sub {
    my $obj = Foo->new();
    return template 'object', { foo => $obj };
};

1;
