package Acme::PrettyCure::CureMint;
use utf8;
use Any::Moose;

with 'Acme::PrettyCure::Role';

sub human_name   {'秋元こまち'}
sub precure_name {'キュアミント'}
sub age          {15}
sub challenge { 'やすらぎの緑の大地、キュアミント!' }

no Any::Moose;
__PACKAGE__->meta->make_immutable;

1;
