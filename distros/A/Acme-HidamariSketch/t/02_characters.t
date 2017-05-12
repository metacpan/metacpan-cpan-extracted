use strict;
use warnings;
use utf8;
binmode(STDOUT, ":utf8");
use Test::More;

use Acme::HidamariSketch;


subtest 'characters' => sub {
    my $hidamari   = Acme::HidamariSketch->new;
    my @characters = $hidamari->characters;

    ok $hidamari;
    ok @characters;
    
    subtest 'ゆの' => sub {
        is $characters[0]->{name_ja},     'ゆの';
        is $characters[0]->{name_en},     'yuno';
        is $characters[0]->{nickname},    'ゆのっち';
        is $characters[0]->{voice_by},    '阿澄 佳奈';
        is $characters[0]->{birthday},    '5/5';
        is $characters[0]->{sign},        '射手座';
        is $characters[0]->{color},       '#FFA500';
        is_deeply 
            $characters[0]->{room_number}, {
                before => undef,
                first  => 201,
                second => 201,
                third  => 201,
            }
        ;
    };
    
    subtest '宮子' => sub {
        is $characters[1]->{name_ja},     '宮子';
        is $characters[1]->{name_en},     'miyako';
        is $characters[1]->{nickname},    '宮ちゃん';
        is $characters[1]->{voice_by},    '水橋 かおり';
        is $characters[1]->{birthday},    '10/10';
        is $characters[1]->{sign},        '天秤座';
        is $characters[1]->{color},       '#FFFF00';
        is_deeply 
            $characters[1]->{room_number}, {
                before => undef,
                first  => 202,
                second => 202,
                third  => 202,
            }
        ;
    };

    subtest 'ヒロ' => sub {
        is $characters[2]->{name_ja},     'ヒロ';
        is $characters[2]->{name_en},     'hiro';
        is $characters[2]->{nickname},    'ヒロ';
        is $characters[2]->{voice_by},    '後藤 邑子';
        is $characters[2]->{birthday},    '6/15';
        is $characters[2]->{sign},        '双子座';
        is $characters[2]->{color},       '#FFC0CB';
        is_deeply 
            $characters[2]->{room_number}, {
                before => 203, 
                first  => 101,
                second => 101,
                third  => undef,
            }
        ;
    };

    subtest '沙英' => sub {
        is $characters[3]->{name_ja},     '沙英';
        is $characters[3]->{name_en},     'sae';
        is $characters[3]->{nickname},    'さえ';
        is $characters[3]->{voice_by},    '新谷 良子';
        is $characters[3]->{birthday},    '11/3';
        is $characters[3]->{sign},        '蠍座';
        is $characters[3]->{color},       '#800080';
        is_deeply 
            $characters[3]->{room_number}, {
                before => 102, 
                first  => 102,
                second => 102,
                third  => undef,
            }
        ;
    };

    subtest '乃莉' => sub {
        is $characters[4]->{name_ja},        '乃莉';
        is $characters[4]->{name_en},        'nori';
        eq_array $characters[4]->{nickname},  qw/のりっぺ ノリスケ ノリコさん/;
        is $characters[4]->{voice_by},       '原田 ひとみ';
        is $characters[4]->{birthday},       '2/6';
        is $characters[4]->{sign},           '水瓶座';
        is $characters[4]->{color},          '#89CEEB';
        is_deeply 
            $characters[4]->{room_number}, {
                before => undef, 
                first  => undef,
                second => 103,
                third  => 103,
            }
        ;
    };

    subtest 'なずな' => sub {
        is $characters[5]->{name_ja},     'なずな';
        is $characters[5]->{name_en},     'nazuna';
        is $characters[5]->{nickname},    'なずな殿';
        is $characters[5]->{voice_by},    '小見川 千明';
        is $characters[5]->{birthday},    '1/7';
        is $characters[5]->{sign},        '山羊座';
        is $characters[5]->{color},       '#F5F5F5';
        is_deeply 
            $characters[5]->{room_number}, {
                before => undef, 
                first  => undef, 
                second => 203,
                third  => 203,
            }
        ;
    };

    subtest '茉里' => sub {
        is $characters[6]->{name_ja},     '茉里';
        is $characters[6]->{name_en},     'matsuri';
        is $characters[6]->{nickname},    undef;
        is $characters[6]->{voice_by},    undef;
        is $characters[6]->{birthday},    undef;
        is $characters[6]->{sign},        undef;
        is $characters[6]->{color},       undef;
        is_deeply 
            $characters[6]->{room_number}, {
                before => undef,
                first  => undef,
                second => undef, 
                third  => 101,
            }
        ;
    };

    subtest 'リリ' => sub {
        is $characters[7]->{name_ja},     'リリ';
        is $characters[7]->{name_en},     'riri';
        is $characters[7]->{nickname},    undef;
        is $characters[7]->{voice_by},    '白石 涼子';
        is $characters[7]->{birthday},    undef;
        is $characters[7]->{sign},        undef;
        is $characters[7]->{color},       undef;
        is_deeply 
            $characters[7]->{room_number}, {
                before => 101,
                first  => undef,
                second => undef, 
                third  => undef,
            }
        ;
    };

    subtest 'みさと' => sub {
        is $characters[8]->{name_ja},     'みさと';
        is $characters[8]->{name_en},     'misato';
        is $characters[8]->{nickname},    undef;
        is $characters[8]->{voice_by},    '小清水 亜美';
        is $characters[8]->{birthday},    undef;
        is $characters[8]->{sign},        undef;
        is $characters[8]->{color},       undef;
        is_deeply 
            $characters[8]->{room_number}, {
                before => 201,
                first  => undef,
                second => undef, 
                third  => undef,
            }
        ;
    };
};


done_testing;

