use strict;
use warnings;
use utf8;
binmode(STDOUT, ":utf8");
use Test::More;

use Acme::HidamariSketch;


subtest 'apartment' => sub {
    my $hidamari  = Acme::HidamariSketch->new;
    my $apartment = $hidamari->apartment;

    ok $hidamari;
    ok $apartment;

    my $yuno   = Acme::HidamariSketch::Yuno->new;
    my $miyako = Acme::HidamariSketch::Miyako->new;
    my $nori   = Acme::HidamariSketch::Nori->new;
    my $nazuna = Acme::HidamariSketch::Nazuna->new;

    is_deeply $apartment->knock(201), $yuno,   'ゆのがお出迎え'  ;
    is_deeply $apartment->knock(202), $miyako, '宮子がお出迎え'  ;
    is_deeply $apartment->knock(203), $nazuna, 'なずながお出迎え';
    is_deeply $apartment->knock(103), $nori,   '乃莉がお出迎え'  ;

    is $apartment->knock,      undef;
    is $apartment->knock(104), undef;
};


done_testing;

