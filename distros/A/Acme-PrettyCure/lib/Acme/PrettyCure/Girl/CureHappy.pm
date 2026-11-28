package Acme::PrettyCure::Girl::CureHappy;
use utf8;
use Moo;

with qw/Acme::PrettyCure::Girl::Role Acme::PrettyCure::Girl::Role::Smile/;

sub human_name   {'星空みゆき'}
sub precure_name {'キュアハッピー'}
sub age          {14}
sub challenge { 'キラキラ輝く未来の光! キュアハッピー!' }
sub color { 200 }
sub image_url { 'http://www.toei-anim.co.jp/tv/precure/images/character/c1_1.jpg' }

1;
