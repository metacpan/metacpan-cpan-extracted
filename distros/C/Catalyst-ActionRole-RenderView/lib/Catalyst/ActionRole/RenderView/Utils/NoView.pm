package Catalyst::ActionRole::RenderView::Utils::NoView;
 
use Moose;
with 'CatalystX::Utils::DoesHttpException';
 
sub status_code { 500 }
sub error { "No View can be found to render." }

__PACKAGE__->meta->make_immutable;
