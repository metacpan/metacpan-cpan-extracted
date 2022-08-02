package Catalyst::View::BasePerRequest::Exception::RenderError;

use Moose;
with 'CatalystX::Utils::DoesHttpException';

has 'render_error' => (is=>'ro', required=>1);

sub status_code { 500 }
sub error { "Error trying to render view: @{[ $_[0]->render_error ]}" }
  
__PACKAGE__->meta->make_immutable;
