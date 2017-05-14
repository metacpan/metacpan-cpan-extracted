package Acme::PrettyCure::CureWindy;
use utf8;
use Any::Moose;

extends 'Acme::PrettyCure::CureEgret';

override 'precure_name' => sub {'キュアウィンディ'};
override 'challenge' => sub {
    qw(
       天空に満ちる月、キュアブライト!
       大地に薫る風、キュアウィンディ!
       ふたりはプリキュア! 
       聖なる泉を汚す者よ!
       アコギな真似はおやめなさい!
    )
};

no Any::Moose;
__PACKAGE__->meta->make_immutable;

1;
