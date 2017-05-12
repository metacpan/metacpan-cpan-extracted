package Acme::PrettyCure::Girl::CureBeat;
use utf8;
use Moo;

with qw/Acme::PrettyCure::Girl::Role Acme::PrettyCure::Girl::Role::Suite/;

use List::MoreUtils qw/any/;

sub fairy_name   {'セイレーン'}
sub human_name   {'黒川エレン'}
sub precure_name {'キュアビート'}
sub challenge { '爪弾くは魂の調べ! キュアビート!' }
sub color { 111 }
sub image_url { 'http://www.toei-anim.co.jp/tv/suite_precure/character/18_01/01.jpg' }

1;
