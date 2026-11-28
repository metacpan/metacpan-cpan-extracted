package Acme::PrettyCure::Girl::CureHeart;
use utf8;
use Moo;

with qw/Acme::PrettyCure::Girl::Role Acme::PrettyCure::Girl::Role::DokiDoki/;

sub human_name   {'相田マナ'}
sub precure_name {'キュアハート'}
sub age          {14}
sub challenge { 'みなぎる愛!キュアハート!' }
sub message { '愛を失くした悲しい%sさん、このキュアハートがあなたのドキドキ取り戻してみせる!' }
sub color { 219 }
sub image_url { 'http://www.toei-anim.co.jp/tv/precure/character/img/cure/image_cure01.png' }

1;
