package Acme::PrettyCure::CureBlossom;
use utf8;
use Any::Moose;

with 'Acme::PrettyCure::Role';

sub human_name   {'花咲つぼみ'}
sub precure_name {'キュアブロッサム'}
sub age          {14}
sub challenge { qw(大地に咲く一輪の花、キュアブロッサム!) }


no Any::Moose;
__PACKAGE__->meta->make_immutable;

1;
