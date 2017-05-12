package Acme::PrettyCure::Girl::CurePeach;
use utf8;
use Moo;

with qw/Acme::PrettyCure::Girl::Role Acme::PrettyCure::Girl::Role::Fresh/;

sub human_name   {'桃園ラブ'}
sub precure_name {'キュアピーチ'}
sub age          {14}
sub challenge { qw(ピンクのハートは愛ある印 もぎたてフレッシュ、キュアピーチ!) }
sub color { 198 }
sub image_url { 'http://www.toei-anim.co.jp/tv/fresh_precure/character/img/main/curepeach_l.jpg' }

1;
