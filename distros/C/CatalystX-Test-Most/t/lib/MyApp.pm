package MyApp;
use Moose;
use namespace::autoclean;
use Catalyst::Runtime 5.80;
extends "Catalyst";
our $VERSION = "0.01";

__PACKAGE__->config( name => "MyApp" );

__PACKAGE__->setup();

1;

