package CatalystX::RequestModel::Utils::InvalidRequestNamespace;
 
use Moose;
with 'CatalystX::Utils::DoesHttpException';
 
has 'ns' => (is=>'ro', required=>1);

sub status_code { 400 }
sub error { "JSON Request does not have namespace: @{[ $_[0]->ns]}" }

__PACKAGE__->meta->make_immutable;
