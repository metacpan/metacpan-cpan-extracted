package Acme::PrettyCure::Girl::CureMarine;
use utf8;
use Moo;

with qw/Acme::PrettyCure::Girl::Role Acme::PrettyCure::Girl::Role::HeartCatch/;

sub human_name   {'来海えりか'}
sub precure_name {'キュアマリン'}
sub age          {14}
sub challenge { qw(海風に揺れる一輪の花、キュアマリン!) }
sub color { 33 }
sub image_url {'http://www.toei-anim.co.jp/tv/hc_precure/images/chara/chara02.jpg'}

1;
