package CatalystX::RequestModel::Utils::InvalidContentType;
 
use Moose;
with 'CatalystX::Utils::DoesHttpException';
 
has 'ct' => (is=>'ro', required=>1);

sub status_code { 415 }
sub error { "Bad request content type not allowed '@{[ $_[0]->ct ]}' " }

__PACKAGE__->meta->make_immutable;
