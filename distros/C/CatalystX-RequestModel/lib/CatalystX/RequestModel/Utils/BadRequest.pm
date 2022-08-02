package CatalystX::RequestModel::Utils::BadRequest;
 
use Moose;
with 'CatalystX::Utils::DoesHttpException';

has 'class' => (is=>'ro', required=>1);
has 'error_trace' => (is=>'ro', required=>1);

sub status_code { 400 }
sub error { "Error trying to create an instance of '@{[ $_[0]->class ]}': @{[ $_[0]->error_trace ]}" }

__PACKAGE__->meta->make_immutable;
