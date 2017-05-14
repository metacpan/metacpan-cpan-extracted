package Acme::PrettyCure::ShinyLuminous;
use utf8;
use Any::Moose;

with 'Acme::PrettyCure::Role';

sub human_name   {'九条ひかり'}
sub precure_name {'シャイニー・ルミナス'}
sub birthday     { Time::Piece->( '1990/02/02', '%Y/%m/%d' ) }
sub age          {13}
sub blood_type   {'AB'}
sub challenge {
    qw(
       輝く命、シャイニールミナス!
       光の心と光の意思
       全てをひとつにするために
    )
}

no Any::Moose;
__PACKAGE__->meta->make_immutable;

1;
