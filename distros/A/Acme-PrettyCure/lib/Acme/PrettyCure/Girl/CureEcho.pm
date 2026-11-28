package Acme::PrettyCure::Girl::CureEcho;
use utf8;
use Moo;

with 'Acme::PrettyCure::Girl::Role';

sub human_name   {'坂上あゆみ'}
sub precure_name {'キュアエコー'}
sub challenge { "想いよ届け! キュアエコー!" }
sub image_url { '' }

1;
