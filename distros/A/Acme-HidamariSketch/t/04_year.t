use strict;
use warnings;
use utf8;
binmode(STDOUT, ":utf8");
use Test::More;

use Acme::HidamariSketch;


subtest 'year' => sub {
    # 今現在のひだまり荘には...
    my $hidamari  = Acme::HidamariSketch->new;
    my $apartment = $hidamari->apartment;

    ok $hidamari;
    ok $apartment;

    # 沙英さんもヒロさんも卒業しちゃってる...
    is $apartment->knock(201)->{name_ja}, 'ゆの';
    is $apartment->knock(202)->{name_ja}, '宮子';
    is $apartment->knock(203)->{name_ja}, 'なずな';
    is $apartment->knock(101)->{name_ja}, '茉里';
    is $apartment->knock(103)->{name_ja}, '乃莉';


    # そんな時は2年目に戻してやると...
    $hidamari->year('second');
    $apartment = $hidamari->apartment;

    # 沙英さん、ヒロさんが帰ってくる!!
    is $apartment->knock(201)->{name_ja}, 'ゆの';
    is $apartment->knock(202)->{name_ja}, '宮子';
    is $apartment->knock(203)->{name_ja}, 'なずな';
    is $apartment->knock(101)->{name_ja}, 'ヒロ';
    is $apartment->knock(102)->{name_ja}, '沙英';
    is $apartment->knock(103)->{name_ja}, '乃莉';


    # リリさんとみさとさんが居た頃まで遡れる
    $hidamari->year('before');
    $apartment = $hidamari->apartment;

    is $apartment->knock(101)->{name_ja}, 'リリ';
    is $apartment->knock(102)->{name_ja}, '沙英';
    is $apartment->knock(201)->{name_ja}, 'みさと';
    is $apartment->knock(203)->{name_ja}, 'ヒロ';
};


done_testing;

