package Acme::PrettyCure::Girl::CureAce;
use utf8;
use Moo;

with qw/Acme::PrettyCure::Girl::Role Acme::PrettyCure::Girl::Role::DokiDoki/;

sub human_name   {'円亜久里'}
sub precure_name {'キュアエース'}
sub age          {10}
sub challenge { '愛の切り札!キュアエース!' }
sub message { '美しさは正義の証、ウインク1つで、あなたのハートを射抜いてさしあげますわ!' }
sub color { 196 }
sub image_url { 'http://www.toei-anim.co.jp/tv/precure/character/img/cure/image_cure05.png' }

1;

