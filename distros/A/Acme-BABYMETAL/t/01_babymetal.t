use strict;
use Test::More 0.98;
use Acme::BABYMETAL;

my $babymetal = new Acme::BABYMETAL;

is scalar $babymetal->members, 3;

is $babymetal->homepage, 'http://www.babymetal.jp/';
is $babymetal->youtube, 'https://www.youtube.com/BABYMETAL';
is $babymetal->facebook, 'https://www.facebook.com/BABYMETAL.jp/';
is $babymetal->instagram, 'https://www.instagram.com/babymetal_official/';
is $babymetal->twitter, 'https://twitter.com/BABYMETAL_JAPAN';


done_testing;

