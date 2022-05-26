package Catalyst::View::BasePerRequest::Exception::ContentBlockError;
  
use Moose;
use namespace::clean -except => 'meta';
   
extends 'CatalystX::Utils::HttpException';

has 'content_name' => (is=>'ro', required=>1);
has 'content_msg' => (is=>'ro', required=>1);
has '+status' => (is=>'ro', init_arg=>undef, default=>sub {500});
has '+errors' => (
  is=>'ro',
  init_arg=>undef, 
  default=>sub { ["Error using content block '@{[ $_[0]->content_name ]}': @{[ $_[0]->content_msg ]}"] },
);
  
__PACKAGE__->meta->make_immutable;
