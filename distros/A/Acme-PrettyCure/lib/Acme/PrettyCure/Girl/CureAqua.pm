package Acme::PrettyCure::Girl::CureAqua;
use utf8;
use Moo;

with qw/Acme::PrettyCure::Girl::Role Acme::PrettyCure::Girl::Role::Five/;

sub human_name   {'水無月かれん'}
sub precure_name {'キュアアクア'}
sub age          {15}
sub challenge { '知性の青き泉、キュアアクア!' }
sub color { 20 }
sub image_url { 'http://www.toei-anim.co.jp/tv/yes_precure5/character/img/body_aqua.jpg' }

1;
