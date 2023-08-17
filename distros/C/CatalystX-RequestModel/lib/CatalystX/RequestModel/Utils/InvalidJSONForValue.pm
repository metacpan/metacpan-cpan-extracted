package CatalystX::RequestModel::Utils::InvalidJSONForValue;
 
use Moose;
with 'CatalystX::Utils::DoesHttpException';
 
has 'param' => (is=>'ro', required=>1);
has 'value' => (is=>'ro', required=>1);
has 'parsing_error' => (is=>'ro', required=>1);

sub status_code { 400 }
sub error { "JSON decode error for parameter '@{[ $_[0]->param]}', value '@{[ $_[0]->value ]}': @{[ $_[0]->parsing_error]}" }

__PACKAGE__->meta->make_immutable;
