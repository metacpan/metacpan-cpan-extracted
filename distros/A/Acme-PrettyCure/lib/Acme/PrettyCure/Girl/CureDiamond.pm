package Acme::PrettyCure::Girl::CureDiamond;
use utf8;
use Moo;

with qw/Acme::PrettyCure::Girl::Role Acme::PrettyCure::Girl::Role::DokiDoki/;

sub human_name   {'菱川六花'}
sub precure_name {'キュアダイヤモンド'}
sub age          {14}
sub challenge { '英知の光!キュアダイヤモンド!' }
sub message { 'このキュアダイヤモンドがあなたの頭を冷やしてあげる!' }
sub color { 69 }
sub image_url { 'http://www.toei-anim.co.jp/tv/precure/character/img/cure/image_cure02.png' }

1;
