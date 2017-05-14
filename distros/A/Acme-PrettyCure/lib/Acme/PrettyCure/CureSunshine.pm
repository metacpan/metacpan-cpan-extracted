package Acme::PrettyCure::CureSunshine;
use utf8;
use Any::Moose;

with 'Acme::PrettyCure::Role';

sub human_name   {'明堂院いつき'}
sub precure_name {'キュアサンシャイン'}
sub age          {14}
sub challenge { qw(陽の光浴びる一輪の花、キュアサンシャイン!) }


no Any::Moose;
__PACKAGE__->meta->make_immutable;

1;
