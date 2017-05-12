use strict;
use warnings;
use utf8;

use Acme::MadokaMagica;
use Acme::MadokaMagica::TvMembers;
use Acme::MadokaMagica::TvMembers::TomoeMami;
use Acme::MadokaMagica::TvMembers::KanameMadoka;
use Acme::MadokaMagica::TvMembers::MikiSayaka;
use Acme::MadokaMagica::TvMembers::SakuraKyoko;
use Acme::MadokaMagica::TvMembers::AkemiHomura;

use Test::More;

subtest 'Charactors' => sub {
    subtest 'Mami' => sub {
        my $mami = Acme::MadokaMagica::TvMembers::TomoeMami->new;
        ok ! $mami->has_qb;
        is $mami->name,       '巴 マミ';
        is $mami->firstname,  'マミ';
        is $mami->lastname,   '巴';
        is $mami->age,        15;
        is $mami->birthday,   '8/28';
        is $mami->blood_type, 'O';
        is $mami->cv,         '水橋かおり';
        is $mami->say,        'ティロ・フィナーレ!!';
        is $mami->color,      'yellow';
        ok $mami->qb;
        ok $mami->has_qb;
        is $mami->name,       'Candeloro';
        is $mami->color,      'black';
    };

    subtest 'Madoka' => sub {
        my $madoka = Acme::MadokaMagica::TvMembers::KanameMadoka->new;
        ok ! $madoka->has_qb;
        is $madoka->name,       '鹿目 まどか';
        is $madoka->firstname,  'まどか';
        is $madoka->lastname,   '鹿目';
        is $madoka->age,        14;
        is $madoka->birthday,   '10/3';
        is $madoka->blood_type, 'A';
        is $madoka->cv,         '悠木碧';
        is $madoka->say,        'ウェヒヒww';
        is $madoka->color,      'Pink';
        ok $madoka->qb;
        ok $madoka->has_qb;
        is $madoka->name,       'Kriemhild_Gretchen';
        is $madoka->color,      'black';
    };

    subtest 'Sayaka' => sub {
        my $sayaka = Acme::MadokaMagica::TvMembers::MikiSayaka->new;
        ok ! $sayaka->has_qb;
        is $sayaka->name,       '美樹 さやか';
        is $sayaka->firstname,  'さやか';
        is $sayaka->lastname,   '美樹';
        is $sayaka->age,         14;
        is $sayaka->birthday,   '8/16';
        is $sayaka->blood_type, 'A';
        is $sayaka->cv,         '喜多村英梨';
        is $sayaka->say,        'あたしってほんとバカ';
        is $sayaka->color,      'Blue';
        ok $sayaka->qb;
        ok $sayaka->has_qb;
        is $sayaka->name,       'Oktavia_Von_Seckendorff';
        is $sayaka->color,      'black';
    };

    subtest 'kyoko' => sub {
        my $kyoko = Acme::MadokaMagica::TvMembers::SakuraKyoko->new;
        ok ! $kyoko->has_qb;
        is $kyoko->name,       '佐倉 杏子';
        is $kyoko->firstname,  '杏子';
        is $kyoko->lastname,   '佐倉';
        is $kyoko->age,        14;
        is $kyoko->birthday,   '6/8';
        is $kyoko->blood_type, 'A';
        is $kyoko->cv,         '野中藍';
        is $kyoko->say,        '喰うかい?';
        is $kyoko->color,      'Red';
        ok $kyoko->qb;
        ok $kyoko->has_qb;
        is $kyoko->name,       'Ophelia';
        is $kyoko->color,      'black';
    };

    subtest 'homura' => sub {
        my $homura = Acme::MadokaMagica::TvMembers::AkemiHomura->new;
        ok ! $homura->has_qb;
        is $homura->name,       '暁美 ほむら';
        is $homura->firstname,  'ほむら';
        is $homura->lastname,   '暁美';
        is $homura->age,        14;
        is $homura->birthday,   '3/12';
        is $homura->blood_type, 'A';
        is $homura->cv,         '斎藤千和';
        is $homura->say,        'それには及ばないわ';
        is $homura->color,      'purple';
        ok $homura->qb;
        ok $homura->has_qb;
        is $homura->name,       'Homulilly';
        is $homura->color,      'black';
    };
};

done_testing;

