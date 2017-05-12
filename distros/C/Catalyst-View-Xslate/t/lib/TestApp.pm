package TestApp;
use strict;
use warnings;
use Catalyst; # qw/-Debug/;

our $VERSION = '0.00019';

__PACKAGE__->config(
    name                  => 'TestApp',
    default_message       => 'hi',
    default_view          => 'Xslate::Pkgconfig',
    encoding => undef
);

__PACKAGE__->setup;
