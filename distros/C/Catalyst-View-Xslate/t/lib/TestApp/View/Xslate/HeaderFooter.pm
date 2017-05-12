package TestApp::View::Xslate::HeaderFooter;
use Moose;
use namespace::autoclean;

extends 'Catalyst::View::Xslate';

__PACKAGE__->config(
    header => [ 'header.tx' ],
    footer => [ 'footer.tx' ],
);

1;