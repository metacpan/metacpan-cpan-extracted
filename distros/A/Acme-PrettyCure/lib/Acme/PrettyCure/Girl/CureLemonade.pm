package Acme::PrettyCure::Girl::CureLemonade;
use utf8;
use Moo;

with qw/Acme::PrettyCure::Girl::Role Acme::PrettyCure::Girl::Role::Five/;

sub human_name   {'春日野うらら'}
sub precure_name {'キュアレモネード'}
sub age          {13}
sub challenge { 'はじけるレモンの香り、キュアレモネード!' }
sub color { 220 }
sub image_url {'http://www.toei-anim.co.jp/tv/yes_precure5/character/img/body_lemonade.jpg'}

1;
