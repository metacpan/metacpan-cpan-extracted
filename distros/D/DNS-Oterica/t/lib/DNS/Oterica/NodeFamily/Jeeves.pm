package DNS::Oterica::NodeFamily::Jeeves;
use Moose;
extends 'DNS::Oterica::NodeFamily';

sub name { 'com.example.jeeves' }

__PACKAGE__->meta->make_immutable;
no Moose;
1;
