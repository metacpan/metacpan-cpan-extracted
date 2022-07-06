package Catalyst::Exception::StructuredParameter;

use Moose;
 
with 'CatalystX::Utils::DoesHttpException';

sub status { 400 }
sub error { "General error with structured parameters." }

__PACKAGE__->meta->make_immutable;
