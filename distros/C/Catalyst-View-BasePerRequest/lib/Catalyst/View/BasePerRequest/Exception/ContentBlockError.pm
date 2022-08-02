package Catalyst::View::BasePerRequest::Exception::ContentBlockError;
  
use Moose;
with 'CatalystX::Utils::DoesHttpException';
 
has 'content_name' => (is=>'ro', required=>1);
has 'content_msg' => (is=>'ro', required=>1);

sub status_code { 500 }
sub error { "Error using content block '@{[ $_[0]->content_name ]}': @{[ $_[0]->content_msg ]}" }
  
__PACKAGE__->meta->make_immutable;
