package Acme::PrettyCure::CureBerry;
use utf8;
use Any::Moose;

with 'Acme::PrettyCure::Role';

sub human_name   {'蒼乃美希'}
sub precure_name {'キュアベリー'}
sub age          {14}
sub challenge { qw(ブルーのハートは希望の印 つみたてフレッシュ、キュアベリー!) }


no Any::Moose;
__PACKAGE__->meta->make_immutable;

1;
