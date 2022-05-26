package Catalyst::View::BasePerRequest::Exception::RenderError;
  
use Moose;
use namespace::clean -except => 'meta';
   
extends 'CatalystX::Utils::HttpException';

has 'render_error' => (is=>'ro', required=>1);
has '+status' => (is=>'ro', init_arg=>undef, default=>sub {500});
has '+errors' => (
  is=>'ro',
  init_arg=>undef, 
  default=>sub { ["Error trying to render view: @{[ $_[0]->render_error ]}"] },
);
  
__PACKAGE__->meta->make_immutable;
