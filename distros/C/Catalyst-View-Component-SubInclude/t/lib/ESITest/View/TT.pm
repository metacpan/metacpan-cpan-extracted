package ESITest::View::TT;
use Moose;

extends 'Catalyst::View::TT';
with 'Catalyst::View::Component::SubInclude';

__PACKAGE__->config(
    TEMPLATE_EXTENSION => '.tt',
    subinclude_plugin => 'Visit',
    subinclude => {
        'HTTP::GET' => {
            class => 'HTTP',
            http_method => 'GET',
            uri_map => {
                '/cpan/' => 'http://search.cpan.org/~',
                '/github/' => 'http://github.com/',
            },
        },
    },
);

1;
