package CatalystX::RequestModel::Utils::InvalidRequestNotIndexed;
 
use Moose;
with 'CatalystX::Utils::DoesHttpException';
 
has 'param' => (is=>'ro', required=>1);

sub status_code { 400 }
sub error { "Request parameter '@{[ $_[0]->param]}' is not indexed" }

__PACKAGE__->meta->make_immutable;
