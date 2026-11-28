package Acme::PrettyCure::Girl::CureMarch;
use utf8;
use Moo;

with qw/Acme::PrettyCure::Girl::Role Acme::PrettyCure::Girl::Role::Smile/;

sub human_name   {'緑川なお'}
sub precure_name {'キュアマーチ'}
sub age          {14}
sub challenge { '勇気リンリン直球勝負! キュアマーチ!' }
sub color { 34 }
sub image_url {'http://www.toei-anim.co.jp/tv/precure/images/character/c4_1.jpg'}

1;
