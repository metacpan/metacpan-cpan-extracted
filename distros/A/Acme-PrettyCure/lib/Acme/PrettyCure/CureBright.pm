package Acme::PrettyCure::CureBright;
use utf8;
use Any::Moose;

extends 'Acme::PrettyCure::CureBloom';

override 'precure_name' => sub {'キュアブライト'};
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
