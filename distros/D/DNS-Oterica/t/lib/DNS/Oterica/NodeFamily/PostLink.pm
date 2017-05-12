package DNS::Oterica::NodeFamily::PostLink;
use Moose;
extends 'DNS::Oterica::NodeFamily';

sub name { 'com.example.postlink' }

__PACKAGE__->meta->make_immutable;
no Moose;
1;
