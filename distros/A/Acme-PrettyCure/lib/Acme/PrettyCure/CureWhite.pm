package Acme::PrettyCure::CureWhite;
use utf8;
use Any::Moose;

use Time::Piece;

with 'Acme::PrettyCure::Role';

sub human_name   {'雪城ほのか'}
sub precure_name {'キュアホワイト'}
sub birthday     { Time::Piece->new( '1990/04/04', '%Y/%m/%d' ) }
sub age          { 14 }
sub blood_type   {'B'}
sub challenge {
    qw(
       光の使者、キュアブラック! 
       光の使者、キュアホワイト! 
       ふたりはプリキュア! 
       闇の力の僕たちよ! 
       とっととおうちに帰りなさい!
    )
}

before 'transform' => sub {
    my ($self, $buddy) = @_;

    die "なぎさがいないと変身できないミポ!" unless ref($buddy) =~ /CureBlack/;
};

after 'transform' => sub {
    my ($self, $buddy) = @_;

    unless ($buddy->is_precure) {
        $buddy->transform($self);
    }
};

no Any::Moose;
__PACKAGE__->meta->make_immutable;

1;
