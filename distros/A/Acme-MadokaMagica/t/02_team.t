use strict;
use warnings;
use utf8;

use Acme::MadokaMagica;
use Test::More;

subtest 'Team' => sub {
    subtest 'Alone' => sub {
        my ($mami) = Acme::MadokaMagica->alone_members;

        is ref $mami, 'Acme::MadokaMagica::TvMembers::TomoeMami';
    };

    subtest 'Main Members' => sub{
        my ($madoka, $homura, $mami, $kyouko, $sayaka) = Acme::MadokaMagica->main_members;

        is ref $madoka, 'Acme::MadokaMagica::TvMembers::KanameMadoka';
        is ref $homura, 'Acme::MadokaMagica::TvMembers::AkemiHomura';
        is ref $mami, 'Acme::MadokaMagica::TvMembers::TomoeMami';
        is ref $kyouko, 'Acme::MadokaMagica::TvMembers::SakuraKyoko';
        is ref $sayaka, 'Acme::MadokaMagica::TvMembers::MikiSayaka';
        is $madoka->name, '鹿目 まどか';
        is $homura->name, '暁美 ほむら';
        is $mami->color, 'yellow';
        is $kyouko->say, '喰うかい?';
        ok $sayaka->qb;
        is $sayaka->name, 'Oktavia_Von_Seckendorff';
        is $homura->say,'それには及ばないわ';
    };

    subtest 'Kyosaya' => sub{
        my ($kyoko, $sayaka) = Acme::MadokaMagica->members_of($Acme::MadokaMagica::KyoSaya);

        is ref $kyoko, 'Acme::MadokaMagica::TvMembers::SakuraKyoko';
        is ref $sayaka, 'Acme::MadokaMagica::TvMembers::MikiSayaka';
        is $kyoko->say, '喰うかい?';
        ok $sayaka->qb;
        is $sayaka->name, 'Oktavia_Von_Seckendorff';
    };

    subtest 'MadoHomu' => sub{
        my ($madoka, $homura) = Acme::MadokaMagica->members_of($Acme::MadokaMagica::MadoHomu);

        is ref $madoka, 'Acme::MadokaMagica::TvMembers::KanameMadoka';
        is ref $homura, 'Acme::MadokaMagica::TvMembers::AkemiHomura';

        is $madoka->name, '鹿目 まどか';
        is $homura->name, '暁美 ほむら';
    };
};

done_testing;
