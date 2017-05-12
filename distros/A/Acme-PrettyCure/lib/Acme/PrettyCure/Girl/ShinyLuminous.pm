package Acme::PrettyCure::Girl::ShinyLuminous;
use utf8;
use Moo;

with 'Acme::PrettyCure::Girl::Role';

sub human_name   {'九条ひかり'}
sub precure_name {'シャイニー・ルミナス'}
sub birthday     { Time::Piece->( '1990/02/02', '%Y/%m/%d' ) }
sub age          {13}
sub blood_type   {'AB'}
sub image_url    {'http://www.toei-anim.co.jp/tv/precure_MH/image/hikari/p01.gif'}
sub challenge {
    qw(
       輝く命、シャイニールミナス!
       光の心と光の意思
       全てをひとつにするために
    )
}
sub color { 213 }

1;
