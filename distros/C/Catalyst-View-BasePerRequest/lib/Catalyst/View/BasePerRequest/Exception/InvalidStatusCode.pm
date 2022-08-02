package Catalyst::View::BasePerRequest::Exception::InvalidStatusCode;

use Moose;
with 'CatalystX::Utils::DoesHttpException';
 
has 'status_code' => (is=>'ro', required=>1);

sub status_code { 500 }
sub error { "This view doesn't support HTTP status code: @{[ $_[0]->status_code ]}" }
  
__PACKAGE__->meta->make_immutable;
