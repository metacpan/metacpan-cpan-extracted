package Acme::PrettyCure::Girl::CureBlossom;
use utf8;
use Moo;

with qw/Acme::PrettyCure::Girl::Role Acme::PrettyCure::Girl::Role::HeartCatch/;

sub human_name   {'花咲つぼみ'}
sub precure_name {'キュアブロッサム'}
sub age          {14}
sub challenge { qw(大地に咲く一輪の花、キュアブロッサム!) }
sub color { 207 }
sub image_url {'http://www.toei-anim.co.jp/tv/hc_precure/images/chara/chara01.jpg'}

1;
