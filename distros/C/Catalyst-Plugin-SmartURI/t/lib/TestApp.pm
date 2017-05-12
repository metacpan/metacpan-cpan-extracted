package TestApp;

use Catalyst qw/SmartURI/;

__PACKAGE__->config({'Plugin::SmartURI' => {
    disposition => 'hostless',
    uri_class => 'MyURI',
}});

__PACKAGE__->setup;

1;
