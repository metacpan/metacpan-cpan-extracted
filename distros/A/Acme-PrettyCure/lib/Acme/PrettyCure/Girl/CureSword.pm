package Acme::PrettyCure::Girl::CureSword;
use utf8;
use Moo;

with qw/Acme::PrettyCure::Girl::Role Acme::PrettyCure::Girl::Role::DokiDoki/;

sub human_name   {'???'}
sub precure_name {'キュアソード'}
sub challenge { '' }
sub color { 183 }
sub image_url { 'http://www.toei-anim.co.jp/tv/dd_precure/img/character/chara_img02_04.png' }

1;
