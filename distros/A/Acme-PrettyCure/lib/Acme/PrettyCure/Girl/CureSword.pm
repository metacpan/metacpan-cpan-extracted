package Acme::PrettyCure::Girl::CureSword;
use utf8;
use Moo;

with qw/Acme::PrettyCure::Girl::Role Acme::PrettyCure::Girl::Role::DokiDoki/;

sub human_name   {'剣崎真琴'}
sub precure_name {'キュアソード'}
sub challenge { '勇気の刃!キュアソード!' }
sub message { 'このキュアソードが、愛の剣であなたの野望を断ち切ってみせる!' }
sub color { 183 }
sub image_url { 'http://www.toei-anim.co.jp/tv/precure/character/img/cure/image_cure04.png' }

1;
