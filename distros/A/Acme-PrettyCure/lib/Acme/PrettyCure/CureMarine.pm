package Acme::PrettyCure::CureMarine;
use utf8;
use Any::Moose;

with 'Acme::PrettyCure::Role';

sub human_name   {'来海えりか'}
sub precure_name {'キュアマリン'}
sub age          {14}
sub challenge { qw(海風に揺れる一輪の花、キュアマリン!) }


no Any::Moose;
__PACKAGE__->meta->make_immutable;

1;
