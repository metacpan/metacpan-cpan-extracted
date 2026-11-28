package Acme::PrettyCure::Girl::CureBlackMH;
use Moo;

extends 'Acme::PrettyCure::Girl::CureBlack';

around 'age' => sub { 15 };
around 'image_url' => sub { 'http://www.toei-anim.co.jp/tv/precure_MH/image/nagisa/p01.gif' };

1;
