package Acme::PrettyCure::CurePeach;
use utf8;
use Any::Moose;

with 'Acme::PrettyCure::Role';

sub human_name   {'桃園ラブ'}
sub precure_name {'キュアピーチ'}
sub age          {14}
sub challenge { qw(ピンクのハートは愛ある印 もぎたてフレッシュ、キュアピーチ!) }


no Any::Moose;
__PACKAGE__->meta->make_immutable;

1;
