package Catalyst::View::BasePerRequest::Exception::BuildViewError;
  
use Moose;
with 'CatalystX::Utils::DoesHttpException';
 
has 'class' => (is=>'ro', required=>1);
has 'build_error' => (is=>'ro', required=>1);

sub status_code { 500 }
sub error { "Error trying to build view '@{[ $_[0]->class ]}': @{[ $_[0]->build_error ]}" }

  
__PACKAGE__->meta->make_immutable;
