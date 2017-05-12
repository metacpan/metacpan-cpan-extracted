package TestApp::View::Xslate::Pkgconfig;
use Moose;
use namespace::autoclean;

extends 'Catalyst::View::Xslate';

__PACKAGE__->config(
  type => 'html',
);

1;
