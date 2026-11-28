package Acme::PrettyCure::Girl::CureSunny;
use utf8;
use Moo;

with qw/Acme::PrettyCure::Girl::Role Acme::PrettyCure::Girl::Role::Smile/;

sub human_name   {'日野あかね'}
sub precure_name {'キュアサニー'}
sub age          {14}
sub challenge { '太陽サンサン熱血パワー! キュアサニー!' }
sub color { 202 }
sub image_url { 'http://www.toei-anim.co.jp/tv/precure/images/character/c2_1.jpg' }

1;
