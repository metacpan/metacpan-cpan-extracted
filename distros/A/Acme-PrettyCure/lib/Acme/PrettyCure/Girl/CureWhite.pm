package Acme::PrettyCure::Girl::CureWhite;
use utf8;
use Moo;

use Time::Piece;

with qw/Acme::PrettyCure::Girl::Role Acme::PrettyCure::Girl::Role::Futari/;

sub human_name   {'雪城ほのか'}
sub precure_name {'キュアホワイト'}
sub birthday     { Time::Piece->new( '1990/04/04', '%Y/%m/%d' ) }
sub age          { 14 }
sub blood_type   {'B'}
sub image_url    {'http://www.toei-anim.co.jp/tv/f_precure/i-images/cha_curewhite.gif'}
sub challenge {
    "\e[38;5;255m\e[48;5;232m光の使者、キュアブラック!\e[0m",
    "\e[38;5;232m\e[48;5;255m光の使者、キュアホワイト!\e[0m",
    "\e[38;5;201mふたりはプリキュア!\e[0m",
    "\e[38;5;232m\e[48;5;255m闇の力の僕たちよ!\e[0m",
    "\e[38;5;255m\e[48;5;232mとっととおうちに帰りなさい!\e[0m",
}
sub color { 255 }

before 'transform' => sub {
    my ($self, $buddy) = @_;

    die "なぎさがいないと変身できないミポ!" unless ref($buddy) =~ /CureBlack/;
};

1;
