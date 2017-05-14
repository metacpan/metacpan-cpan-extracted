package Acme::PrettyCure::CureEgret;
use utf8;
use Any::Moose;

with 'Acme::PrettyCure::Role';

sub human_name   {'美翔舞'}
sub precure_name {'キュアイーグレット'}
sub birthday     { Time::Piece->( '1992/11/20', '%Y/%m/%d' ) }
sub age          {14}
sub blood_type   {'AB'}
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

    die "咲がいないと変身できないチョピ!" unless ref($buddy) =~ /Cure(Bloom|Bright)/;
};

after 'transform' => sub {
    my ($self, $buddy) = @_;

    unless ($buddy->is_precure) {
        $buddy->transform($self);
    }
};

use Acme::PrettyCure::CureWindy;
sub powerup { Acme::PrettyCure::CureWindy->new(is_precure => shift->is_precure) }

no Any::Moose;
__PACKAGE__->meta->make_immutable;

1;
