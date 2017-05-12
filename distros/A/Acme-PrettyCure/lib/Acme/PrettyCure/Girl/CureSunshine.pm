package Acme::PrettyCure::Girl::CureSunshine;
use utf8;
use Moo;

with qw/Acme::PrettyCure::Girl::Role Acme::PrettyCure::Girl::Role::HeartCatch/;

sub human_name   {'明堂院いつき'}
sub precure_name {'キュアサンシャイン'}
sub age          {14}
sub challenge { qw(陽の光浴びる一輪の花、キュアサンシャイン!) }
sub color { 227 }
sub image_url { 'http://www.toei-anim.co.jp/tv/hc_precure/images/chara/chara14.jpg' }

1;
