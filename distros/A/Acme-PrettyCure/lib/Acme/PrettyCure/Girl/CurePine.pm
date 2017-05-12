package Acme::PrettyCure::Girl::CurePine;
use utf8;
use Moo;

with qw/Acme::PrettyCure::Girl::Role Acme::PrettyCure::Girl::Role::Fresh/;

sub human_name   {'山吹祈里'}
sub precure_name {'キュアパイン'}
sub age          {14}
sub challenge { qw(イエローハートは祈りの印 とれたてフレッシュ、キュアパイン!) }
sub color { 214 }
sub image_url { 'http://www.toei-anim.co.jp/tv/fresh_precure/character/img/main/curepain_l.jpg' }

1;
