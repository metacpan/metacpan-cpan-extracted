package Acme::PrettyCure::CureBloom;
use utf8;
use Any::Moose;

with 'Acme::PrettyCure::Role';

sub human_name   {'日向咲'}
sub precure_name {'キュアブルーム'}
sub birthday     { Time::Piece->( '1992/08/07', '%Y/%m/%d' ) }
sub age          {14}
sub blood_type   {'O'}
sub challenge {
    qw(
       輝く金の花、キュアブルーム!
       きらめく銀の翼、キュアイーグレット!
       ふたりはプリキュア! 
       聖なる泉を汚す者よ!
       アコギな真似はおやめなさい!
    )
}

before 'transform' => sub {
    my ($self, $buddy) = @_;

    die "舞がいないと変身できないラピ!" unless ref($buddy) =~ /Cure(Egret|Windy)/;
};

after 'transform' => sub {
    my ($self, $buddy) = @_;

    unless ($buddy->is_precure) {
        $buddy->transform($self);
    }
};

use Acme::PrettyCure::CureBright;
sub powerup { Acme::PrettyCure::CureBright->new(is_precure => shift->is_precure) }

no Any::Moose;
__PACKAGE__->meta->make_immutable;

1;
