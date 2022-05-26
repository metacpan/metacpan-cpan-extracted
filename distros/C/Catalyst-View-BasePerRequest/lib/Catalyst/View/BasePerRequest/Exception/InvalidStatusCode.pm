package Catalyst::View::BasePerRequest::Exception::InvalidStatusCode;
  
use Moose;
use namespace::clean -except => 'meta';
   
extends 'CatalystX::Utils::HttpException';

has 'status_code' => (is=>'ro', required=>1);
has '+status' => (is=>'ro', init_arg=>undef, default=>sub {500});
has '+errors' => (
  is=>'ro',
  init_arg=>undef, 
  default=>sub { ["This view doesn't support HTTP status code: @{[ $_[0]->status_code ]}"] },
);
  
__PACKAGE__->meta->make_immutable;
