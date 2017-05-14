package Acme::PrettyCure::CurePine;
use utf8;
use Any::Moose;

with 'Acme::PrettyCure::Role';

sub human_name   {'山吹祈里'}
sub precure_name {'キュアパイン'}
sub age          {14}
sub challenge { qw(イエローハートは祈りの印 とれたてフレッシュ、キュアパイン!) }


no Any::Moose;
__PACKAGE__->meta->make_immutable;

1;
