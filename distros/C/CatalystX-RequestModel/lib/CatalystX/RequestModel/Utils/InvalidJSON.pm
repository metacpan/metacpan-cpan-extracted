package CatalystX::RequestModel::Utils::InvalidJSON;
 
use Moose;
with 'CatalystX::Utils::DoesHttpException';
 
has 'parsing_error' => (is=>'ro', required=>1);

sub status_code { 400 }
sub error { "JSON decode error ': @{[ $_[0]->parsing_error]}" }

__PACKAGE__->meta->make_immutable;
