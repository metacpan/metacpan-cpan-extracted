package Acme::PrettyCure::Girl::CureDream;
use utf8;
use Moo;

with qw/Acme::PrettyCure::Girl::Role Acme::PrettyCure::Girl::Role::Five/;

sub human_name   {'夢原のぞみ'}
sub precure_name {'キュアドリーム'}
sub age          {14}
sub challenge { '大いなる希望の力、キュアドリーム!' }
sub color { 199 }
sub image_url { 'http://www.toei-anim.co.jp/tv/yes_precure5/character/img/body_dream.jpg' }

1;
