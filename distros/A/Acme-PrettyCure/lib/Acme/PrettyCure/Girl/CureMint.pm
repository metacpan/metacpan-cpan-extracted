package Acme::PrettyCure::Girl::CureMint;
use utf8;
use Moo;

with qw/Acme::PrettyCure::Girl::Role Acme::PrettyCure::Girl::Role::Five/;

sub human_name   {'秋元こまち'}
sub precure_name {'キュアミント'}
sub age          {15}
sub challenge { 'やすらぎの緑の大地、キュアミント!' }
sub color { 34 }
sub image_url { 'http://www.toei-anim.co.jp/tv/yes_precure5/character/img/body_mint.jpg' }

1;
