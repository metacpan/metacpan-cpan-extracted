package Acme::PrettyCure::Girl::CureWindy;
use utf8;
use Moo;

extends 'Acme::PrettyCure::Girl::CureEgret';

around 'precure_name' => sub {'キュアウィンディ'};
around 'challenge' => sub {
    "\e[38;5;229m天空に満ちる月、キュアブライト!\e[0m",
    "\e[38;5;45m大地に薫る風、キュアウィンディ!\e[0m",
    "\e[38;5;201mふたりはプリキュア!\e[0m",
    "\e[38;5;45m聖なる泉を汚す者よ!\e[0m",
    "\e[38;5;229mアコギな真似はおやめなさい!\e[0m",
};

1;
