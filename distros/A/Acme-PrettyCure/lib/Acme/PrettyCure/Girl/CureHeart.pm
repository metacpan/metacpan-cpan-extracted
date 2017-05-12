package Acme::PrettyCure::Girl::CureHeart;
use utf8;
use Moo;

with qw/Acme::PrettyCure::Girl::Role Acme::PrettyCure::Girl::Role::DokiDoki/;

sub human_name   {'相田マナ'}
sub precure_name {'キュアハート'}
sub age          {14}
sub challenge { 'みなぎる愛!キュアハート' }
sub color { 219 }
sub image_url { 'http://www.toei-anim.co.jp/tv/dd_precure/img/character/chara_img02_01.png' }

1;
