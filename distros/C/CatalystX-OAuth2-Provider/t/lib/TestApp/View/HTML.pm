package TestApp::View::HTML;
use Moose;
use namespace::autoclean;

extends 'Catalyst::View::TT';

__PACKAGE__->config(
    render_die => 1,
    WRAPPER => 'wrapper.tt',
    TEMPLATE_EXTENSION => '.tt',
    INCLUDE_PATH => [ TestApp->path_to('root') ],
);

1;