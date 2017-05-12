package Acme::PrettyCure::Girl::CureEgret;
use utf8;
use Moo;

with qw/Acme::PrettyCure::Girl::Role Acme::PrettyCure::Girl::Role::Futari/;

sub human_name   {'美翔舞'}
sub precure_name {'キュアイーグレット'}
sub birthday     { Time::Piece->( '1992/11/20', '%Y/%m/%d' ) }
sub age          {14}
sub blood_type   {'AB'}
sub image_url    {'http://www.toei-anim.co.jp/tv/precure_SS/character/chara_mai01.gif'}
sub challenge {
    "\e[38;5;198m輝く金の花、キュアブルーム!\e[0m",
    "\e[38;5;250mきらめく銀の翼、キュアイーグレット!\e[0m",
    "\e[38;5;201mふたりはプリキュア!\e[0m",
    "\e[38;5;250m聖なる泉を汚す者よ!\e[0m",
    "\e[38;5;198mアコギな真似はおやめなさい!\e[0m",
}

before 'transform' => sub {
    my ($self, $buddy) = @_;

    die "咲がいないと変身できないチョピ!" unless ref($buddy) =~ /Cure(Bloom|Bright)/;
};

use Acme::PrettyCure::Girl::CureWindy;
sub powerup { 
    my $self = shift;
    my $precure = Acme::PrettyCure::Girl::CureWindy->new;
    $precure->is_precure($self->is_precure);
    return $precure;
}

1;
