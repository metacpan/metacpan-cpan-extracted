package Catalyst::Exception::StructuredParameter;

use Moose;
use namespace::clean -except => 'meta';
 
extends 'CatalystX::Utils::HttpException';

has '+status' => (is=>'ro', init_arg=>undef, default=>sub {400});
has '+errors' => (is=>'ro', init_arg=>undef, default=>sub { ["General error with structured parameters."] });

__PACKAGE__->meta->make_immutable;
