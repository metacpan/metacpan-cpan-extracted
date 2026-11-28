package Acme::PrettyCure::Girl::CureRosetta;
use utf8;
use Moo;

with qw/Acme::PrettyCure::Girl::Role Acme::PrettyCure::Girl::Role::DokiDoki/;

sub human_name   {'四葉ありす'}
sub precure_name {'キュアロゼッタ'}
sub age          {14}
sub challenge { 'ひだまりポカポカ♪キュアロゼッタ!' }
sub message { '世界を制するのは愛だけです。さあ、あなたも私と愛を育んでくださいな' }
sub color { 214 }
sub image_url { 'http://www.toei-anim.co.jp/tv/precure/character/img/cure/image_cure03.png' }

1;
