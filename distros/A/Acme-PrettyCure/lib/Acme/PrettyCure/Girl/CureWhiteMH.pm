package Acme::PrettyCure::Girl::CureWhiteMH;
use Moo;

extends 'Acme::PrettyCure::Girl::CureWhite';

around 'age' => sub { 15 };
around 'image_url' => sub { 'http://www.toei-anim.co.jp/tv/precure_MH/image/honoka/p01.gif' };

1;
