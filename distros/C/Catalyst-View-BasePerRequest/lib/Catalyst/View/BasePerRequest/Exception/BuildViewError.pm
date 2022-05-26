package Catalyst::View::BasePerRequest::Exception::BuildViewError;
  
use Moose;
use namespace::clean -except => 'meta';
   
extends 'CatalystX::Utils::HttpException';

has 'class' => (is=>'ro', required=>1);
has 'build_error' => (is=>'ro', required=>1);
has '+status' => (is=>'ro', init_arg=>undef, default=>sub {500});
has '+errors' => (
  is=>'ro',
  init_arg=>undef, 
  default=>sub { ["Error trying to build view '@{[ $_[0]->class ]}': @{[ $_[0]->build_error ]}"] },
);
  
__PACKAGE__->meta->make_immutable;
