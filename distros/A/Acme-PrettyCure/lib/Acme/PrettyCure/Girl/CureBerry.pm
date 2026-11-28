package Acme::PrettyCure::Girl::CureBerry;
use utf8;
use Moo;

with qw/Acme::PrettyCure::Girl::Role Acme::PrettyCure::Girl::Role::Fresh/;

sub human_name   {'蒼乃美希'}
sub precure_name {'キュアベリー'}
sub age          {14}
sub challenge { qw(ブルーのハートは希望の印 つみたてフレッシュ、キュアベリー!) }
sub color { 63 }
sub image_url { 'http://www.toei-anim.co.jp/tv/fresh_precure/character/img/main/curepeach_l.jpg' }

1;
