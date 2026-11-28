package Acme::PrettyCure::Girl::CureMuse;
use utf8;
use Moo;

with qw/Acme::PrettyCure::Girl::Role Acme::PrettyCure::Girl::Role::Suite/;

sub human_name   {'調辺アコ'}
sub precure_name {'キュアミューズ'}
sub challenge { '爪弾くは女神の調べ! キュアミューズ!' }
sub age          {9}
sub color { 228 }
sub image_url {'http://www.toei-anim.co.jp/tv/suite_precure/character/35_01/01.jpg'}

1;
